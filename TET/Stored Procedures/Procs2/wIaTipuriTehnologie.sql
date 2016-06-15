CREATE procedure wIaTipuriTehnologie @sesiune varchar(50), @parXML xml  
as 


	IF OBJECT_ID('tempdb..#tipuritehn') IS NOT NULL
		drop table #tipuritehn

	create table #tipuritehn(cod varchar(20), denumire varchar(100), ordine int)

	insert into #tipuritehn (cod, denumire, ordine)
	select 'P','Produs',1 UNION 
	select 'R', 'Reper',2 UNION 
	select 'S', 'Serviciu' ,3 UNION	
	select 'I', 'Interventie' ,5



	select * from #tipuritehn order by ordine for xml raw, root('Date')
	select 'P' as initializare for xml raw, root('Mesaje')
