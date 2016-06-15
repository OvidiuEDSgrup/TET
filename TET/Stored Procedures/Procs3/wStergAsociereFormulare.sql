
CREATE PROCEDURE wStergAsociereFormulare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idAsoc INT, @mesaj VARCHAR(500)

	SET @idAsoc = isnull(@parXML.value('(/*/@idAsociere)[1]', 'int'),
							@parXML.value('(/*/*/@idAsociere)[1]', 'int'))

	DELETE
	FROM WebConfigFormulare
	WHERE idAsociere = @idAsoc
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuAsociereFormulare)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
