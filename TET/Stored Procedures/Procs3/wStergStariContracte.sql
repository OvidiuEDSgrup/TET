
CREATE PROCEDURE wStergStariContracte @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idStare INT, @mesaj varchar(500)

	SET @idStare = @parXML.value('(/*/@idStare)[1]', 'int')

	DELETE StariContracte
	WHERE idStare = @idStare
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergStariContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
