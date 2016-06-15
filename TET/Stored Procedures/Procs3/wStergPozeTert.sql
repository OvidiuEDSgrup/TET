
CREATE PROCEDURE wStergPozeTert @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @poza VARCHAR(255), @mesaj VARCHAR(500)

SET @cod = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
SET @poza = @parXML.value('(/*/*/@poza)[1]', 'varchar(255)')

BEGIN TRY
	DELETE TOP (1) pozeRIA
	WHERE tip = 'T'
		AND cod = @cod
		AND Fisier = @poza
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergPozeTert)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
