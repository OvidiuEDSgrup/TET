
/** Procedura este aferenta machetei de Tipuri Documente **/
CREATE PROCEDURE wScriuTipuriDoc @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tip VARCHAR(5), @denumire VARCHAR(50), @update BIT, @idTip INT, @mesaj VARCHAR(500)

	SET @idTip = @parXML.value('(/*/@idTip)[1]', 'int')
	SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(5)')
	SET @denumire = @parXML.value('(/*/@denumire)[1]', 'varchar(50)')
	SET @update = isnull(@parXML.value('(/*/@update)[1]', 'bit'), 0)

	IF @update = 1
	BEGIN
		UPDATE TipuriDocumente
		SET denumire = @denumire
		WHERE idTip = @idTip

		RETURN
	END

	INSERT INTO TipuriDocumente (tip, denumire)
	VALUES (@tip, @denumire)
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuTipuriDoc)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
