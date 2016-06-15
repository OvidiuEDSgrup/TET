
CREATE PROCEDURE wStergPlajeDocumente @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idPlaja INT, @mesaj VARCHAR(500)

	SET @idPlaja = @parXML.value('(/*/@idPlaja)[1]', 'int')

	IF EXISTS (
			SELECT 1
			FROM asocieredocfiscale
			WHERE id = @idPlaja
			)
		RAISERROR ('Plaja selectata pentru stergere are asocieri !', 11, 1)

	DELETE
	FROM docfiscale
	WHERE id = @idPlaja
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergPlajeDocumente)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
