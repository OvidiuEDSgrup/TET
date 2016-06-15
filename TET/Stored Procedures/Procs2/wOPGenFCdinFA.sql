--***
create procedure wOPGenFCdinFA @sesiune varchar(50),@parXML xml 
as  
begin try
   declare @Subunitate varchar(1),@Tip varchar(2),@Contract varchar(20),@Tert varchar(20) ,@Punct_livrare varchar(20),@Data datetime,
		   @Cod varchar(20),@Cantitate float (20),@Pret float ,@Pret_promotional varchar(20),@Discount varchar(20),@Termen datetime,
		   @Factura varchar(20),@Cant_disponibila varchar(20),@Cant_aprobata varchar(20),@Cant_realizata varchar(20),@Valuta varchar(10),
		   @Cota_TVA  varchar(20),@Suma_TVA varchar(20),@Mod_de_plata varchar(20),@UM varchar(20),@Zi_scadenta_din_luna varchar (2),
		   @Explicatii varchar(50),@Numar_pozitie varchar (10),@Utilizator varchar(20), @loc_de_munca char(9), 
		   @cont_de_stoc char(13), @cont_corespondent char(13), @data_lunii datetime,@datap varchar(20),@datajos datetime ,@cont_tva char(13),@proc_tva float, @modplata char(8),@numarpoz int,
		   @lmUtil varchar (10),@gestiune varchar(15),@termenlimita datetime,@stare int, @codi_stoc char(13),@stoc float,@x int, @scadenta int,
		   @punctlivrare varchar(10),@TermPeSurse int
		   
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output	   
	exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
	
    select @Contract=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),	
           @tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), ''),
           @termenlimita=ISNULL(@parXML.value('(/parametri/@termenlimita)[1]', 'datetime'), '01/01/1901'),
           @stare=ISNULL(@parXML.value('(/parametri/@stare)[1]', 'int'), '0')
          
    if @stare<>'1'
       raiserror('Nu se poate genera comanda de aprovizionare deoarece contractul nu este in stare Definitiv!',16,1)      
			declare @aiCG int, @liCG int
			declare @fltLmUt int	
			declare @LmUtiliz table(valoare varchar(200))
			insert into @LmUtiliz (valoare)
			select cod from lmfiltrare where utilizator=@utilizator
			select @fltLmUt=isnull((select count(1) from @LmUtiliz),0)  			
			declare @fXML xml ,@NrDocFisc varchar(10), @serie varchar(9)
							set @tip='RM'
							set @fXML = '<row/>'
							set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')
							set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
							set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
							exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
							set @factura=@NrDocFisc      
   set @x=0
   declare crspozcon cursor for 
   select p.subunitate,p.tip, p.contract, p.data, p.tert, p.cod, p.termen,  t.cantitate, t.pret, p.cant_realizata,p.numar_pozitie,
		  con.loc_de_munca,con.explicatii,con.valuta,con.gestiune, con.scadenta,con.punct_livrare
			 from pozcon p
                  inner join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert
                  inner join termene t on con.subunitate=t.subunitate and con.contract=t.contract and con.data=t.data and con.tert=t.tert
                             and t.cod=(case when @TermPeSurse=0 then p.cod else ltrim(str(p.numar_pozitie)) end)
				  where  p.subunitate='1' and con.stare='1' and p.cant_realizata=0  and p.termen <=@termenlimita and con.contract=@contract 
   open crspozcon
   fetch next from crspozcon into @subunitate,@tip, @contract, @data, @tert, @cod, @termen, @cantitate, @pret, @cant_realizata, @numar_pozitie,
								  @loc_de_munca, @explicatii, @valuta, @gestiune, @scadenta, @punctlivrare
								  
   while @@FETCH_STATUS=0
   begin
       set @proc_tva=ISNULL((select max(val_numerica )from par where Tip_parametru='GE' and Parametru='COTATVA' and Val_logica=1),0)
	   set @cont_de_stoc=(select max(cont )from nomencl where cod=@cod)
	   set @cont_corespondent=(select max(cont_ca_beneficiar )from terti where tert=@tert)
	   set @cont_tva=ISNULL((select max(rtrim(val_alfanumerica)) from par where Tip_parametru='GE' and Parametru='CCTVA' and Val_logica=1),'4427.01')
	--if @numarpoz is null set @numarpoz=0
    if not exists (select 1 from con where subunitate=@Subunitate and tip='FC' and Tert=@tert and data=@termenlimita and Contract_coresp=@Contract)
    begin
     set @numarpoz=0
     insert into con 
	 (Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Stare,Loc_de_munca,Gestiune,
	 Termen,Scadenta,Discount,Valuta,Curs,
	 Mod_plata,Mod_ambalare,Factura,Total_contractat,Total_TVA,Contract_coresp,Mod_penalizare,
	 Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,
	 Responsabil,Responsabil_tert,Explicatii,Data_rezilierii) 
	 select 
	 @Subunitate, 'FC', @factura, @tert, @punctlivrare, @termenlimita,'1',@loc_de_munca,@gestiune,
	 @termenlimita, @scadenta, 0, @valuta, '',
	 '','','',0,0,@contract,'',
	 0,0,0,0,0,0,'',1,0,
	 '','',@explicatii,'1921-01-01'
    end 
    select @factura=contract from con where subunitate=@Subunitate and tip='FC' and Tert=@tert and Data=@termenlimita 
    delete from pozcon where subunitate=@Subunitate and tip='FC' and Tert=@tert and Contract=@factura and Data<=@termenlimita
						and cod=@cod and Termen=@termen
    set @numarpoz=isnull((select max(numar_pozitie) from pozcon where Contract=@factura and tert=@tert ),0)+1
	set @Suma_TVA=round((@Cantitate*@pret*@proc_tva/100),2)
	set @x=@x+1
	insert into pozcon 
	(Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,
	Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,
	Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,
	Data_operarii,Ora_operarii) 
	select 
	@Subunitate, 'FC', @factura, @tert, @punctlivrare, @termenlimita, @cod, @Cantitate,
	@pret, 0, 0, @termen, '',@Cantitate, '', @cant_realizata,
	@valuta,@proc_tva, @Suma_TVA, '',0,  0, @explicatii, @numarpoz, @Utilizator,
	convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
	
	update con set Total_contractat=isnull((select SUM(round(cantitate*pret,2)) from pozcon
					where subunitate=@Subunitate and tip='FC' and Tert=@tert and Contract=@factura),0),
	               Total_TVA=isnull((select SUM(Suma_tva)from pozcon 
					where tip='FC' and tert=@tert and Subunitate=@Subunitate and Contract=@factura),0)
	       where Subunitate=@Subunitate and tip='FC' and tert=@tert and Contract=@factura
	fetch next from crspozcon into @subunitate,@tip, @contract, @data, @tert, @cod, @termen,  @cantitate, @pret, @cant_realizata, @numar_pozitie,
									@loc_de_munca, @explicatii, @valuta, @gestiune, @scadenta, @punctlivrare
    end
	begin try 
		close crspozcon 
	end try 
	begin catch end catch
	begin try 
		deallocate crspozcon 
	end try 
	begin catch 
	end catch
	if @x=0 
	select 'Nu s-a generat comanda de aprovizionare' as textMesaj for xml raw, root('Mesaje')
    else 
	select 'S-a generat comanda de aprovizionare cu numarul: '+rtrim(convert(varchar(20),@Factura))+' cu data de:'+convert(varchar(20),@termenlimita,103)+'!' as textMesaj for xml raw, root('Mesaje')
	end try  
begin catch  
	declare @eroare varchar(200) 
		set @eroare=ERROR_MESSAGE()
raiserror(@eroare, 16, 1) 
end catch
