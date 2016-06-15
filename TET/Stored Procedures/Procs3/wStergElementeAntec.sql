
CREATE PROCEDURE wStergElementeAntec @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @mesaj VARCHAR(500)

SET @cod = isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), '')

BEGIN TRY
	IF (
			SELECT COUNT(1)
			FROM elemantec
			WHERE element_parinte = @cod
			) > 0
		RAISERROR ('Elementul ales pentru stergere este parinte pentru alte elemente!!', 11, 1
				)

	DELETE
	FROM elemantec
	WHERE element = @cod
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergElementeAntec)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
