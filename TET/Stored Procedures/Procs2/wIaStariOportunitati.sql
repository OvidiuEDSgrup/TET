CREATE procedure wIaStariOportunitati @sesiune varchar(50), @parXML xml  
as 


	IF OBJECT_ID('tempdb..#stariop') IS NOT NULL
		drop table #stariop

	create table #stariop(cod varchar(20), denumire varchar(100), ordine int)

	insert into #stariop (cod, denumire, ordine)
	select 'C','Castigata',2 UNION ALL
	select 'D', 'Deschisa',1 UNION ALL
	select 'P', 'Pierduta' ,3


	select * from #stariop order by ordine for xml raw, root('Date')
