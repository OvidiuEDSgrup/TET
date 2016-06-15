
CREATE PROCEDURE wScriuLocatii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(13), @descriere VARCHAR(30), @parinte VARCHAR(13), @gestiune VARCHAR(9), @um VARCHAR(3), @capacitate FLOAT, 
	@update BIT, @eroare VARCHAR(400)

BEGIN TRY
	SET @cod = @parXML.value('(/row/@codlocatie)[1]', 'varchar(13)')
	SET @update = @parXML.value('(/row/@update)[1]', 'bit')
	SET @descriere = @parXML.value('(/row/@descriere)[1]', 'varchar(30)')
	SET @um = @parXML.value('(/row/@um)[1]', 'varchar(3)')
	SET @parinte = @parXML.value('(/row/@parinte)[1]', 'varchar(13)')
	SET @gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(9)')
	SET @capacitate = @parXML.value('(/row/@capacitate)[1]', 'float')

	IF @update = 1
	BEGIN
		UPDATE locatii
		SET Descriere = @descriere, Cod_gestiune=@gestiune,UM=@um, Cod_grup=@parinte, Capacitate=@capacitate
		WHERE Cod_locatie = @cod
	END
	ELSE
	BEGIN
		INSERT INTO locatii (Cod_locatie, Este_grup, Cod_grup, UM, Capacitate, Cod_gestiune, Incarcare, Nivel, Descriere
			)
		VALUES (@cod, 0, @parinte, @um, @capacitate, @gestiune, 0, 0, @descriere)

		UPDATE locatii
		SET Este_grup = 1
		WHERE Cod_locatie = @parinte
	END
END TRY

BEGIN CATCH
	SET @eroare = '(wScriuLocatii) ' + ERROR_MESSAGE()

	RAISERROR (@eroare, 11, 1)
END CATCH
