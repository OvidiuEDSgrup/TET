
CREATE PROCEDURE [dbo].[wStergPozTehnologii] @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE [type] = 'P'
			AND [name] = 'wStergPozTehnologiiSP'
		)
BEGIN
	EXEC wStergPozTehnologiiSP @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

BEGIN TRY
	DECLARE @idPozitie INT, @idTehnologie INT, @parinteTopPozitie INT, @eroare VARCHAR(256), @codTehn VARCHAR(20)

	SET @idPozitie = ISNULL(@parXML.value('(/row/row/@idReal)[1]', 'int'), 0)
	SET @parinteTopPozitie = ISNULL(@parXML.value('(/row/row/@parinteTop)[1]', 'int'), 0)
	SET @idTehnologie = ISNULL(@parXML.value('(/row/@idTehn)[1]', 'int'), 0)

	SELECT @codTehn = cod
	FROM pozTehnologii
	WHERE id = @idTehnologie
		AND tip = 'T'

	IF @idTehnologie <> @parinteTopPozitie
	BEGIN
		SET @eroare = 'Elementul nu apartine direct de tehnologia selectata! Editati tehnologia care il contine direct !'

		RAISERROR (@eroare, 11, 1)
	END

	DELETE
	FROM pozTehnologii
	WHERE id = @idPozitie
		OR parinteTop = @idPozitie
		OR idp = @idPozitie

	DECLARE @docXMLIaPozTehn XML

	SET @docXMLIaPozTehn = '<row cod_tehn="' + rtrim(@codTehn) + '"/>'

	EXEC wIaPozTehnologii @sesiune = @sesiune, @parXML = @docXMLIaPozTehn
END TRY

BEGIN CATCH
	SET @eroare = ERROR_MESSAGE() + ' (wStergPozTehnologii)'

	RAISERROR (@eroare, 11, 1)
END CATCH
