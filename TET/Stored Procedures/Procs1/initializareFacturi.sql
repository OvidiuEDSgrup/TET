--***
CREATE PROCEDURE initializareFacturi @sesiune VARCHAR(50), @parXML XML
AS
/* Initializare stocuri
	exec initializareFacturi @sesiune='',@parXML='<row an="2014" luna="3"/>'
	=> 31.12.2013 
*/

BEGIN TRY
	declare		
		@an int,@luna int, @data datetime, @sub varchar(9), @parXMLFact xml
	select	
		@an=@parXML.value('(/*/@an)[1]','int'),
		@luna=@parXML.value('(/*/@luna)[1]','int')
	
	select 
		@data=dateadd(day,-1,dateadd(month,@luna,dateadd(year,@an-1901,'01/01/1901')))

	exec luare_date_par 'GE','SUBPRO',0,0, @sub output

	IF OBJECT_ID('tempdb.dbo.#tmp_fact') IS NOT NULL
		drop table #tmp_fact

	CREATE TABLE #tmp_fact(
		[Subunitate] [char](9) NOT NULL,
		[Loc_de_munca] [char](9) NOT NULL,
		[Tip] [varchar](20) NOT NULL,
		[Factura] [char](20) NOT NULL,
		[Tert] [char](13) NOT NULL,
		punct_livrare varchar(20), 
		[Data] [datetime] NOT NULL,
		[Data_scadentei] [datetime] NOT NULL,
		[Valoare] [float] NOT NULL,
		[TVA_11] [float] NOT NULL,
		[TVA_22] [float] NOT NULL,
		[Valuta] [char](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Valoare_valuta] [float] NOT NULL,
		[Achitat] [float] NOT NULL,
		[Sold] [float] NOT NULL,
		[Cont_de_tert] [varchar](20) NULL,
		[Achitat_valuta] [float] NOT NULL,
		[Sold_valuta] [float] NOT NULL,
		[Comanda] [char](40) NOT NULL,
		[Data_ultimei_achitari] [datetime] NOT NULL,
		[RAND] int
	) 

	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'

	set @parXMLFact=(select '' as furnbenef, DATEADD(YEAR,-10, @data) as datajos, @data as datasus for xml raw)
	exec pFacturi @sesiune=null, @parXML=@parXMLFact

	insert into #tmp_fact 
		(Subunitate, Loc_de_munca, Tip, Factura, Tert, punct_livrare, Data, Data_scadentei, Valoare, TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, 
		Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari, [rand])
	select 
		@sub, max(loc_de_munca), furn_benef, rtrim(factura), rtrim(tert), rtrim(punct_livrare), min(data), min(data_scadentei), sum(convert(decimal(17,2),valoare)) valoare, 0, 0, max(valuta), max(curs), 
		sum(convert(decimal(17,2),total_valuta)) valoare_valuta, sum(convert(decimal(17,2),achitat)) achitat, sum(convert(decimal(17,2),valoare-achitat)), cont_de_tert,
		sum(convert(decimal(17,2),achitat_valuta)) achitat_valuta, sum(convert(decimal(17,2),total_valuta-achitat_valuta)), max(comanda), max(data_platii), 
		row_number() over (partition by furn_benef, tert, factura order by furn_benef, tert, factura,cont_de_tert )
	from #docfacturi
	--from dbo.fFacturi('', DATEADD(YEAR,-10, @data), @data, null, null, null, null, null, null,null, null)
	group by furn_benef, tert, punct_livrare, factura, cont_de_tert

	begin tran fimp
		delete factimpl

		insert into factimpl (Subunitate, Loc_de_munca, Tip, Factura, Tert, Data, Data_scadentei, Valoare, TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, 
			Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari, punct_livrare) 	
		select
			Subunitate, Loc_de_munca, (case tip when 'F' then 0x54 else 0x46 end) ,rtrim(Factura)+ (case [rand] when 1 then '' else 'I'+convert(varchar(2), rand-1) end), 
			Tert, Data, Data_scadentei, Valoare, TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari, punct_livrare
		from #tmp_fact
	commit tran fimp
END TRY

begin catch
	IF @@trancount>0
		rollback tran fimp
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
