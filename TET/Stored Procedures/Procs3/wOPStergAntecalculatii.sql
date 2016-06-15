
CREATE PROCEDURE wOPStergAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
--Procedura se foloseste pentru stergerea unui set de antecalculatii (dupa numar document de generare)
DECLARE @numarDoc VARCHAR(20), @mesaje VARCHAR(500)

SET @numarDoc = isnull(@parXML.value('(/parametri/@numarDoc)[1]', 'varchar(20)'), '')

BEGIN TRY
	SELECT idPoz AS id
	INTO #deSters
	FROM antecalculatii
	WHERE numar = @numarDoc

	DELETE
	FROM pozAntecalculatii
	WHERE id IN (
			SELECT id
			FROM #deSters
			)
		OR idp IN (
			SELECT id
			FROM #deSters
			)

	DELETE
	FROM antecalculatii
	WHERE numar = @numarDoc
END TRY

BEGIN CATCH
	SET @mesaje = ERROR_MESSAGE() + ' (wOPStergAntecalculatii)'

	RAISERROR (@mesaje, 11, 1)
END CATCH
