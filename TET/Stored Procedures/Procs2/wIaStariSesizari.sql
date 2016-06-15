CREATE procedure wIaStariSesizari @sesiune varchar(50), @parXML xml  
as 


	IF OBJECT_ID('tempdb..#starisez') IS NOT NULL
		drop table #starisez

	create table #starisez(cod varchar(20), denumire varchar(100), ordine int)

	insert into #starisez (cod, denumire, ordine)
	select 'N','Nepreluata',1 UNION ALL
	select 'L', 'In lucru',2 UNION ALL
	select 'F', 'Finalizata' ,3


	select * from #starisez order by ordine for xml raw, root('Date')
