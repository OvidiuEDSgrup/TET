
CREATE PROCEDURE wScriuJurnalOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
DECLARE 
	@idOP INT, @operatie VARCHAR(1000), @stare VARCHAR(20), @utilizator VARCHAR(100), @mesaj VARCHAR(400)

BEGIN TRY
	SET @stare = @parXML.value('(/*/@stare)[1]', 'varchar(20)')
	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

	/** Daca nu se transmite stare-> ramane ultima stare, doar se jurnalizeaza modificarea **/
	IF @stare IS NULL
		SELECT TOP 1 @stare = stare
		FROM JurnalOrdineDePlata
		WHERE idOP = @idOP
		ORDER BY data DESC

	SET @operatie = @parXML.value('(/*/@operatie)[1]', 'varchar(1000)')

	/** Daca nu se transmite operatia, se va jurnaliza ca "modificare" */
	IF @operatie IS NULL
		SET @operatie = 'Modificare'

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	INSERT INTO JurnalOrdineDePlata (idOp, data, operatie, stare, utilizator)
	SELECT @idOP, GETDATE(), @operatie, @stare, @utilizator
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuJurnalOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
