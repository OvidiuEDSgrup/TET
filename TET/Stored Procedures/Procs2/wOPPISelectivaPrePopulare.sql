CREATE PROCEDURE wOPPISelectivaPrePopulare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @lm VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME, @valuta VARCHAR(20), @tipOperatiune VARCHAR(2), 
		@utilizator varchar(50),@data datetime, @suma float, @cont varchar(40), @numar varchar(13), @curs float

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @tipOperatiune = isnull(@parXML.value('(/*/@tipOperatiune)[1]', 'varchar(2)'),'')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),'1901-01-01')
	SET @numar = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(13)'),'')
	SET @cont = isnull(@parXML.value('(/*/@cont)[1]', 'varchar(40)'),'')
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(20)'),'')
	SET @lm = ISNULL(@parXML.value('(/*/@lm)[1]', 'varchar(20)'),'') 
	SET @valuta = ISNULL(@parXML.value('(/*/@valuta)[1]', 'varchar(20)'),'')
	SET @suma = ISNULL(@parXML.value('(/*/@suma)[1]', 'float'),'')	
	SET @curs = ISNULL(@parXML.value('(/*/@curs)[1]', 'float'),'')
	
	DECLARE @dateInitializare XML
	
	set @dateInitializare=
	(
		select @valuta as valuta, @tipOperatiune as tipOperatiune, @tert as tert, convert(char(10), @data, 101) as data,
			@lm as lm, CONVERT(decimal(17,5),@suma) as suma, RTRIM(@cont) as cont, RTRIM(@numar) as numar, CONVERT(decimal(12,5),@curs) as curs
		for xml raw ,root('row')
	)
	
	SELECT 'Operatie pentru plati/incasari facturi.'  nume, 'PI' codmeniu, 'D' tipmacheta,'RE' tip,'PI' subtip,'O' fel,
	 (SELECT @dateInitializare ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPISelectivaPrePopulare)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
