CREATE procedure wIaRatingOportunitati @sesiune varchar(50), @parXML xml  
as 


	IF OBJECT_ID('tempdb..#ratingiop') IS NOT NULL
		drop table #ratingiop

	create table #ratingiop(cod varchar(20), denumire varchar(100), ordine int)

	insert into #ratingiop (cod, denumire, ordine)
	select 'C','Cold',1 UNION ALL
	select 'W', 'Warm',2 UNION ALL
	select 'H', 'Hot' ,3


	select * from #ratingiop order by ordine for xml raw, root('Date')
