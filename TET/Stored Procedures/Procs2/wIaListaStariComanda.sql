
create procedure wIaListaStariComanda @sesiune varchar(50), @parXML XML  
as
	declare 
		@idLansare int, @stareComanda varchar(10)

	select @idLansare = @ParXML.value('(/*/@idLansare)[1]','int')

	IF OBJECT_ID('tempdb.dbo.#stariComenzi') IS NOT NULL
		drop table #stariComenzi

	create table #stariComenzi (cod varchar(10), denumire varchar(500), ordine int)
	insert into #stariComenzi  (cod, denumire, ordine)
	select 'S', 'Simulare',1 UNION
	select 'P', 'Pregatire',2 UNION
	select 'L', 'Lansata',3 UNION
	select 'A', 'Alocata',4 UNION
	select 'I', 'Inchisa',5  UNION
	select 'N', 'Anulata',6  UNION
	select 'B', 'Blocata',7
	  
	/*
		Ca si regula generala, nu lasam schimbarea starii sa fie facuta intr-una "inferioara".
	*/
	
	select top 1 @stareComanda =  stare from JurnalComenzi where idLansare=@idLansare order by data desc
	
	delete 	#stariComenzi where ordine<=(select top 1 ordine from #stariComenzi where cod=@stareComanda)
	
	/*
		Procedura permite modificarea tabelului temporara dupa reguli proprii
		Ex. Nu permite starea "Anulata" niciodata sau 
			Nu permite stare "Alocata" daca comanda nu a fost "Lansata"
		ETC
	
	*/
	IF EXISTS (Select 1 from sys.objects where name ='wIaListaStariComandaSP')
		exec wIaListaStariComandaSP @sesiune=@sesiune, @parXML=@parXML

	select * from #stariComenzi order by ordine for xml raw, root('Date')

	select top 1 cod as initializare from #stariComenzi order by ordine for xml raw, root('Mesaje')
