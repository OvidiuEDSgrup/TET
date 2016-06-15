CREATE procedure wIaStariSarcini @sesiune varchar(50), @parXML xml  
as 


	IF OBJECT_ID('tempdb..#starisar') IS NOT NULL
		drop table #starisar

	create table #starisar(cod varchar(20), denumire varchar(100), ordine int)

	insert into #starisar (cod, denumire, ordine)
	select 'N','Nepreluata',1 UNION ALL
	select 'L', 'In lucru',2 UNION ALL
	select 'F', 'Finalizata' ,3


	select * from #starisar order by ordine for xml raw, root('Date')
