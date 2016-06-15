
CREATE PROCEDURE wStergAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @id INT, @idPoz INT, @mesaj VARCHAR(500)

BEGIN TRY
	SET @id = isnull(@parXML.value('(/row/@idAntec)[1]', 'int'), '') (
			SELECT @idPoz = idPoz
			FROM antecalculatii
			WHERE idAntec = @id
			)

	DELETE
	FROM antecalculatii
	WHERE idAntec = @id

	DELETE
	FROM pozAntecalculatii
	WHERE id = @idPoz
		OR idp = @idPoz
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + '(wStergAntecalculatii)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
