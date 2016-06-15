
CREATE PROCEDURE wOPRefacereCapacitati @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @gestiune VARCHAR(9), @codlocatie VARCHAR(13), @eroare VARCHAR(400)

BEGIN TRY
	SET @codlocatie = @parXML.value('(/*/@codlocatie)[1]', 'varchar(13)')
	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(9)')

	IF isnull(@codlocatie, '') = ''
		RAISERROR ('Cod locatie invalid!', 11, 1)

	UPDATE locatii
	SET capacitate = isnull((
				SELECT sum(l.capacitate)
				FROM locatii l
				WHERE l.cod_gestiune = locatii.cod_gestiune
					AND l.cod_locatie LIKE RTrim(locatii.cod_locatie) + '%'
					AND l.este_grup = 0
				), 0)
	WHERE (
			0 = 0
			OR cod_gestiune = @gestiune
			)
		AND cod_locatie = @codlocatie
		AND este_grup = 1
END TRY

BEGIN CATCH
	SET @eroare = '(wOPRefacereCapacitati) ' + ERROR_MESSAGE()

	RAISERROR (@eroare, 11, 1)
END CATCH
