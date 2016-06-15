
CREATE PROCEDURE wOPSchimbareStareOrdinePlata @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @idOP int, @stare varchar(20), @stare_noua varchar(20), @docJurnalizare xml
	SELECT @idOP = @parXML.value('(/parametri/@idOP)[1]', 'int'),
		@stare = @parXML.value('(/parametri/@stare)[1]', 'varchar(20)'),
		@stare_noua = @parXML.value('(/parametri/@stare_noua)[1]', 'varchar(20)')

	IF ISNULL(@stare, '') <> 'Finalizat'
		RAISERROR('Este permisa schimbarea starii doar din Finalizat in Operat!', 16, 1)

	SET @docJurnalizare =
	(
		SELECT @idOP AS idOP, @stare_noua AS stare,
			'Modificare stare: ' + @stare + ' -> ' + @stare_noua AS operatie
		FOR XML raw
	)

	EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @docJurnalizare

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
