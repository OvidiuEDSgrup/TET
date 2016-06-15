
CREATE PROCEDURE wStergStariDocumente @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idStare INT, @mesaj varchar(500)

	SET @idStare = @parXML.value('(/*/@idStare)[1]', 'int')

	DELETE StariDocumente
	WHERE idStare = @idStare
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergStariDocumente)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
