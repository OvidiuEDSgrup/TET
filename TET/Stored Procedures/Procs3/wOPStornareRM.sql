---*** 
---***   
create procedure [dbo].[wOPStornareRM] @sesiune varchar(50), @parXML xml   
as   
begin try 
	declare @subunitate char(9), @numar varchar(20), @tert varchar(40), @utilizator varchar(40), @dtStornRM datetime, @lunabloc int,@anulbloc int,
			@databloc datetime, @nrStornRM varchar(40), @dtRM datetime, @explicatii varchar(300)
	select	@numar = ISNULL(@parXML.value('(/parametri/@numar)[1]','varchar(40)'),''),
			@dtStornRM = ISNULL(@parXML.value('(/parametri/@dtStornRM)[1]','datetime'),'1900-01-01'),
			@nrStornRM = ISNULL(@parXML.value('(/parametri/@nrStornRM)[1]','varchar(20)'),''),
			@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(13)'), ''), 
			@dtRM = ISNULL(@parXML.value('(/parametri/@data)[1]','datetime'),'1900-01-01')
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
   if @numar=''
		raiserror('Completati numar receptie pentru stornare',16,1)
	set @lunabloc = isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
	set @anulbloc = isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)      
        
	if @lunabloc not between 1 and 12 or @anulbloc<=1901       
		set @databloc='01/01/1901'       
	else       
		set @databloc=dateadd(month,1,convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))      
	if @databloc>@dtStornRM      
		raiserror('Data storno trebuie sa fie o data ulterioara lunii blocate ',11,1) 
		
	if (select max (stare) from pozdoc where Subunitate = @subunitate and pozdoc.tip = 'RM' and numar = @numar and tert = @tert) = 4      
		raiserror('Receptie deja stornata!',16,1)      
	if @nrStornRM=''
	begin	
		declare @NrDocFisc int, @fXML xml, @tipPentruNr varchar(2)      
		set @tipPentruNr='RM'  
		set @fXML = '<row/>'      
		set @fXML.modify ('insert attribute codMacheta {"DO"} into (/row)[1]')      
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')      
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
	        
		exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
		
		if ISNULL(@NrDocFisc, 0)<>0      
			set @nrStornRM=LTrim(RTrim(CONVERT(char(20), @NrDocFisc)))      
		else      
			raiserror('Eroare la generare numar document RM!!',16,1)       
	end
	
	
   insert into pozdoc(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,       
						Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,
						Data_operarii,Ora_operarii,
						Cod_intrare,Cont_de_stoc, Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,
						Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,
						Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,       
						Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,       
						Accize_cumparare,Accize_datorate,Contract,Jurnal)              
   select Subunitate,'RM',@nrStornRM,pozdoc.cod,@dtStornRM, pozdoc.Gestiune, -Cantitate,Pret_valuta,Pret_de_stoc,Adaos, pozdoc.Pret_vanzare, 
					pozdoc.Pret_cu_amanuntul,-TVA_deductibil,pozdoc.Cota_TVA,@utilizator, 
					convert(datetime,convert(char(10),GETDATE(),110),110), replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''),
					Cod_intrare, pozdoc.cont_de_stoc, Cont_corespondent, TVA_neexigibil, pozdoc.Pret_amanunt_predator,      
					Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,pozdoc.Loc_de_munca,Comanda,Barcod, 
					pozdoc.cont_intermediar, Cont_venituri, Discount, tert,@nrStornRM, Gestiune_primitoare,Numar_DVI,
					8,pozdoc.Grupa,Cont_factura ,pozdoc.Valuta,Curs, @dtStornRM, @dtStornRM, Procent_vama,Suprataxe_vama,
					Accize_cumparare,Accize_datorate,Contract,Jurnal            
  from pozdoc             
  where Subunitate = @subunitate and pozdoc.tip = 'RM' and numar = @numar and Data_facturii = @dtRM and tert=@tert
  
  update pozdoc set stare = 4, barcod = @nrStornRM 
  where Subunitate = @subunitate and pozdoc.tip = 'RM' and 
		numar = @numar and Data_facturii = @dtRM and tert=@tert
  
  
  set @explicatii='factura stornata:'+@numar+' din RM cu data '+CONVERT(char(10),@dtRM,101)         
  if not exists (select 1 from anexadoc where Subunitate=@subunitate and tip='RM' and Numar=@nrStornRM and data=@dtStornRM)    
       insert into anexadoc  
       (Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,  
       Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)  
       select  
       @subunitate,'RM',@nrStornRM,@dtStornRM,'','','',  
       '','','','','',@explicatii,'',''  
   else    
       update anexadoc set Observatii=@explicatii where Subunitate=@subunitate and tip='RM' and Numar=@nrStornRM and data=@dtStornRM    
	
	if exists (select Numar from pozdoc where Subunitate = @subunitate and pozdoc.tip='RM' and Numar = @nrStornRM and Data=@dtStornRM)      
		select 'wOPStornareDoc:S-a generat documentul de tip RM cu numarul '+rtrim(@nrStornRM)+' din data '+convert(char(10),@dtStornRM,103) as textMesaj for xml raw, root('Mesaje')      
	else      
		raiserror('Din anumite motive nu s-a generat nici un document storno!!! ',11,1)      
	
end try
begin catch
	declare @eroare varchar(500)
	set @eroare='(wOPStornareRM):'+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1)   
end catch
