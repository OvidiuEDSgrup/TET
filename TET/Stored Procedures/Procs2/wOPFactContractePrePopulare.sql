-- procedura folosita pentru generarea de facturi din contracte.
CREATE PROCEDURE wOPFactContractePrePopulare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @lm VARCHAR(20), @gestiune VARCHAR(20), @grupa VARCHAR(20), @mesaj VARCHAR(400), 
		@dataJos DATETIME, @dataSus DATETIME, @valuta VARCHAR(20), @punct_livrare VARCHAR(20), @tipContract VARCHAR(2), 
		@utilizator varchar(50), @idContractFiltrat int

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @tipContract = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),'') -- filtrare dupa tip contract
	SET @idContractFiltrat = isnull(@parXML.value('(/*/@idContract)[1]', 'int'),0) -- filtrare un contract
	SET @dataJos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'),'1901-01-01') -- data inferioara pt. filtrare
	SET @dataSus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'),'2999-01-01') -- data superioara pt. filtrare
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(20)'),'') -- filtru tert
	SET @punct_livrare = isnull(@parXML.value('(/*/@punct_livrare)[1]', 'varchar(20)'),'') -- filtru punct livrare in cadrul tertului
	SET @lm = ISNULL(@parXML.value('(/*/@lm)[1]', 'varchar(20)'),'') 
	SET @gestiune = ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),'')
	SET @valuta = ISNULL(@parXML.value('(/*/@valuta)[1]', 'varchar(20)'),'') -- filtru valuta
	
	
	DECLARE @dateInitializare XML
	
	set @dateInitializare=
	(
		select convert(char(10), @dataJos, 101) as datajos, convert(char(10), @dataSus, 101) as datasus,
			@valuta as valuta, @tipContract as tip, @idContractFiltrat as idContract, @tert as tert,
			@lm as lm, @gestiune as gestiune
		for xml raw ,root('row')
	)
	
	SELECT 'Operatie pentru generare facturi contracte'  nume, 'CS' codmeniu, 'D' tipmacheta,'CS' tip,'FC' subtip,'O' fel,
	 (SELECT @dateInitializare ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPFactContractePrePopulare)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
