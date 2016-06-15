--***
create procedure initializareAnFacturiRIA(@data_initializare datetime)
as

-- exec initializareAnFacturiRIA @data_initializare='2014-01-01'
begin try
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa 
			operatia in aceste conditii!',16,1)
		return
	end
		
	declare @sub char(9), @epsilon decimal(6,5), @anulinit int
	set @epsilon=0.001
	set @sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' 
		and parametru='SUBPRO'), '')
	set @data_initializare=dbo.boy(@data_initializare)
	set @anulinit=YEAR(@data_initializare)
		
	--exec VerificareIntegritateFacturi @de la Data Implementarii,@data_initializare,0
	--declare @data_implementarii datetime, @nLunaImpl int, @nAnImpl int
	--set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' 
	--		and parametru='ANULIMPL'),0)
	--set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' 
	--		and parametru='LUNAIMPL'),0)
	--set @data_implementarii=convert(varchar(10),@nAnImpl)+'-'+convert(varchar(10),@nLunaImpl)+'-1'
	--set	@data_implementarii=dateadd(d,-1,dateadd(M,1,@data_implementarii))
	-- nu trebuie sa se verifice de la data_implementarii!
	declare @data_inceput datetime, @data_sfarsit datetime
	set	@data_inceput=dateadd(y,-1,@data_initializare)
	set	@data_sfarsit=dateadd(d,-1,@data_initializare)
	-- aici vom renunta:
	--exec VerificareIntegritateFacturi @data_inceput, @data_sfarsit, 0

	declare @o_zi_inainte datetime, @parXMLFact xml
	set @o_zi_inainte=dateadd(d,-1,@data_initializare)

	/* se preia in tabela #pfacturi prin procedura pFacturi, in locul functiei fFacturiCen */
	if object_id('tempdb..#pfacturi') is not null 
		drop table #pfacturi
	create table #pfacturi (subunitate varchar(9))
	exec CreazaDiezFacturi @numeTabela='#pfacturi'
	set @parXMLFact=(select '' as furnbenef, null as datajos, @o_zi_inainte as datasus, 1 as cen, @epsilon as soldmin, 0 as semnsold for xml raw)
	exec pFacturi @sesiune=null, @parXML=@parXMLFact

	-- aici vom face dedublare, ca la stocuri
	select max(@data_initializare) as data_an, Subunitate, max(Loc_de_munca) Loc_de_munca, (case when Tip=0x54 then 'F' else 'B' end) as tip, Factura, Tert, min(Data) data, 
		min(Data_scadentei) data_scadentei, sum(convert(decimal(17,2),Valoare)) valoare, 0 tva_11, max(tva) tva_22, max(Valuta) valuta, max(Curs) curs, 
		sum(convert(decimal(17,2),Valoare_valuta)) Valoare_valuta, sum(convert(decimal(17,2),Achitat)) Achitat, sum(convert(decimal(17,2),Sold)) Sold, 
		Cont_factura, sum(convert(decimal(17,2),Achitat_valuta)) Achitat_valuta, sum(convert(decimal(17,2),Sold_valuta)) Sold_valuta, max(Comanda) comanda, 
		max(Data_ultimei_achitari) as Data_ultimei_achitari, 
		row_number() over (partition by subunitate, tip, tert, factura order by subunitate, tip, tert, factura) as nrrand
	into #istfact
	from #pfacturi
	group by subunitate, tip, tert, factura, cont_factura

	delete from #istfact where abs(sold)<0.01 and abs(Sold_valuta)<0.01

	delete istfact where subunitate=@sub and Data_an=@data_initializare
		
	insert into istfact(Data_an, Subunitate, Loc_de_munca, Tip, 
		Factura, 
		Tert, Data, Data_scadentei, Valoare, TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari)
	select data_an, Subunitate, Loc_de_munca, tip,
		(case when nrrand=1 then ltrim(Factura) else 'S'+replace(substring(convert(char(10),@data_initializare,3),4,5),'/','')+replace(str(row_number() over (order by subunitate, tert),8),' ','0') end), 
		Tert, Data, Data_scadentei, Valoare, tva_11, tva_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, cont_factura, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari
	from #istfact
	--from dbo.fFacturiCen('','01/01/1901',@o_zi_inainte,null,null,null,null,null,@epsilon,0, null) f

	exec setare_par 'GE','ULT_AN_IN','Ultimul an initializare facturi',1,@anulinit,''
end try
begin catch
	declare @eroare varchar(1000)
	set @eroare='initializareAnFacturiRIA: '+rtrim(ERROR_MESSAGE())
	raiserror(@eroare,16,1)
end catch

