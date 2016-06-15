--***
create procedure wOPRaportZ @sesiune varchar(50), @parXML xml          
as        
       
declare @subunitate char(9),@tip char(2),@numar char(8),@data datetime, @userASiS varchar(20), 
@numars char(8),@gestiune char(9), @lm char(9), @lunabloc int,@anulbloc int, @databloc datetime,
@contcasa char(13), @contvenit char(13), @tipgestiune char(1), @err int, @eroare varchar(254),
@sumadepusa decimal(8,2),@gestutiliz varchar(13)

set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output        
set @gestiune = ISNULL(@parXML.value('(/parametri/@gestiune)[1]', 'varchar(9)'), '')        
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')       
set @sumadepusa = ISNULL(@parXML.value('(/parametri/@sumadepusa)[1]', 'decimal(8,2)'), 0)

set @gestutiliz=dbo.wfProprietateUtilizator('GESTPV', @userASIS)


declare @Ct707 char(13), @AnGest707 int 
set @Ct707=''
set @AnGest707=0
select @Ct707=val_alfanumerica from par where tip_parametru='GE' and parametru='CVMARFA'
select @AnGest707=convert(int, val_logica) from par where tip_parametru='GE' and parametru='CONTVV'
set @contvenit=RTrim(@Ct707)+(case when @AnGest707=1 then '.'+RTrim(@Gestiune) else '' end)

set @contcasa=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='CONTCASA' and cod=@userASiS),'')
set @lm=ISNULL((select MAX(Loc_de_munca) from gestcor where Gestiune=@gestiune),'')
set @tipgestiune = (select isnull(Tip_gestiune,'') from gestiuni where subunitate=@subunitate and Cod_gestiune = @gestiune)
--set @plata_inc=ISNULL(@parXML.value('(/parametri/@plata_inc)[1]', 'char(1)'), '')     
--set @tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), '')           
set @tip='IC'    
--set @numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'char(8)'), '')        
--set @datadoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'datetime'), '')        
--set @tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'char(13)'), '')        
--set @numars=ISNULL(@parXML.value('(/parametri/@numars)[1]', 'char(8)'), '')         
set @numars=rtrim(@gestiune)+rtrim(convert(char(3),datepart(dayofyear,@data)))+right(convert(char(4),(year(@data))),1)
      
set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
if @lunabloc not between 1 and 12 or @anulbloc<=1901 
	set @databloc='01/01/1901' 
else 
	set @databloc=dateadd(month,1,convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

begin try  
/*	if @numars=''
	begin
		declare @NrDocFisc int, @fXML xml
		
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute codMacheta {"PI"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {"IB"} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
		--set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		--set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
		
		exec wIauNrDocFiscale @fXML, @NrDocFisc output
		
		if ISNULL(@NrDocFisc, 0)<>0
			set @numars=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
	end */
	set @err = 0
	if isnull(@numars,'')=''
		set @err=1 
	--if not exists (select 1 from bp where Factura_chitanta=1 and Loc_de_munca = @gestiune and Data = @data) and @err=0
	--	set @err=2
	if @contcasa=''
		set @err=3
	if @gestiune not in (@gestutiliz)
		set @err=4
	if abs(datediff(day,getdate(),@data))>31
		set @err=5
	if @err>0
		raiserror('Mesaj eroare', 16, 1) 
	else 
	begin
	  delete from pozplin 
	  where Subunitate=@subunitate and Cont=@contcasa and Data=@data and Cont_corespondent=@contvenit and Plata_incasare=@tip and numar_pozitie=1
	  delete from pozplin 
	  where Subunitate=@subunitate and Cont=@contcasa and Data=@data and Cont_corespondent='767' and Plata_incasare=@tip and numar_pozitie=2
	  delete from pozplin 
	  where Subunitate=@subunitate and Cont=@contcasa and Data=@data and Cont_corespondent='5811' and Plata_incasare='PD' and numar_pozitie=3

	--insert suma fara discount	
if exists (select 1 from bp where Factura_chitanta=1 and Loc_de_munca = @gestiune and Data = @data and tip='21')
	  INSERT INTO pozplin(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, 
	  Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, 
	  Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)     
	  select @subunitate, @contcasa, max(Data), @numars, @tip, '', @numars, @contvenit, SUM(cantitate*pret), 
	  '', 0, 0, 0, 24, round(SUM(cantitate*pret*(1-1/(1+cota_tva/100))),2), 'Vanzari PVria', @lm, '', @userASiS, convert(datetime,convert(char(10),GETDATE(),110),110), 
	  replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''), 1, '', 0, 0, ''
	  from bp where Factura_chitanta=1 and Loc_de_munca = @gestiune and Data = @data and tip='21'
	  -- ar trebui tip='31' sau diversificare dupa tipuri, problema este ca '31' nu are TVA...
	--insert discount
if exists (select 1 from bp where Factura_chitanta=1 and Loc_de_munca = @gestiune and Data = @data and tip='21' and discount<>0)
	  INSERT INTO pozplin(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, 
	  Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, 
	  Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)     
	  select @subunitate, @contcasa, max(Data), @numars, @tip, '', @numars, '767', -SUM(cantitate*pret*discount/100), 
	  '', 0, 0, 0, 24, -round(SUM(cantitate*pret*discount/100*(1-1/(1+cota_tva/100))),2), 'Discount PVria', @lm, '', @userASiS, convert(datetime,convert(char(10),GETDATE(),110),110), 
	  replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''), 2, '', 0, 0, ''
	  from bp where Factura_chitanta=1 and Loc_de_munca = @gestiune and Data = @data and tip='21' and discount<>0
	 
	  insert into pozplin (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, 
	  Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, 
	  Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)
	  select @subunitate, @contcasa, @Data, 'V'+@numars, 'PD', '', '', '5811', @sumadepusa, 
	  '', 0, 0, 0, 24, 0, 'Depuneri PVria', @lm, '', @userASiS, convert(datetime,convert(char(10),GETDATE(),110),110), 
	  replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''), 3, '', 0, 0, ''
	  
	  
	  select 'S-a generat documentul IC (incasare) cu numarul '+rtrim(@numars)+' din data '+convert(char(10),@data,103) 
	  +' cu suma de '+rtrim(isnull(convert(char(20),(select SUM(total) from bp where Factura_chitanta=1 and Loc_de_munca = @gestiune and Data = @data and tip='21')),0))+' lei'
	  +' si depunere in valoare de '+rtrim(convert(char(20),@sumadepusa))+ ' lei.' as textMesaj for xml raw, root('Mesaje')
		end
end try  

begin catch  
	if @err=1
		set @eroare='Nu este configurata plaja de documente pentru tipul Incasari (IB)!' 
	else if @err=2
		set @eroare='Nu exista bonuri pentru gestiunea si data selectate!' 
	else if @err=3
		set @eroare='Utilizatorul nu are contul de casa definit!'
	else if @err=4
		set @eroare='Nu aveti drept pe gestiunea selectata!'
	else if @err=5
		set @eroare='Nu puteti genera incasare pe o data cu mai mult de o luna in urma!'
	else
		set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
