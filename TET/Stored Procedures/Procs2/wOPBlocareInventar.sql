
--***
CREATE PROCEDURE wOPBlocareInventar (@sesiune VARCHAR(50), @parXML XML)
AS
DECLARE @gestiune VARCHAR(9), @data DATETIME, @eroare VARCHAR(400)

BEGIN TRY
	SET @gestiune = isnull(@parXML.value('(/parametri/@gestiune)[1]', 'varchar(9)'), '')
	SET @data = @parXML.value('(parametri/@data)[1]', 'datetime')

	IF NOT EXISTS (
			SELECT 1
			FROM antetinv
			WHERE Gestiune = @gestiune
				AND data = @data
				AND tip = 'G'
				AND blocat IN (0, 1)
			)
		RAISERROR ('Inventarul selectat nu este corespunzator', 16, 1)

	UPDATE antetinv
	SET Blocat = 2
	WHERE Gestiune = @gestiune
		AND data = @data
		AND tip = 'G'
		AND blocat IN (0, 1)
END TRY

BEGIN CATCH
	SET @eroare = '(wOPBlocareInventar): ' + ERROR_MESSAGE()

	RAISERROR (@eroare, 16, 1)
END CATCH
