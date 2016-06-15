
CREATE PROCEDURE wStergFisiereAtasate @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idFisier INT, @mesaje VARCHAR(500)

	SET @idFisier = @parXML.value('(/*/@idFisier)[1]', 'int')

	IF @idFisier IS NULL
		RAISERROR ('Nu s-a putut identifica fisierul', 11, 1)

	DELETE TOP (1)
	FROM FisiereContract
	WHERE idFisier = @idFisier
END TRY

BEGIN CATCH
	SET @mesaje = ERROR_MESSAGE() + ' (wStergFisiereAtasate)'

	RAISERROR (@mesaje, 11, 1)
END CATCH
