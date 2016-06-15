
CREATE PROCEDURE wOPSchimbareStareInventar @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @mesaj VARCHAR(400), @idInventar INT, @stare INT

	SET @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')

	UPDATE AntetInventar
	SET stare = @stare
	WHERE idInventar = @idInventar
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPSchimbareStareInventar)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
