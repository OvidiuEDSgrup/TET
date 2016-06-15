
/** Procedura este aferenta machetei de Tipuri Documente **/
CREATE PROCEDURE wStergTipuriDoc @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idTip INT, @tipDoc VARCHAR(5), @mesaj VARCHAR(500)

BEGIN TRY
	SET @idTip = @parXML.value('(/*/@idTip)[1]', 'int')
	SET @tipDoc = @parXML.value('(/*/@tip)[1]', 'varchar(5)')

	IF EXISTS (
			SELECT 1
			FROM docfiscale df
			INNER JOIN asocieredocfiscale adf ON df.id = adf.id
				AND df.tipDoc = @tipDoc
			)
		RAISERROR ('Pe acest tip de document exista asocieri! Verificati asocierile de documente.', 11, 1)

	DELETE
	FROM TipuriDocumente
	WHERE idTip = @idTip
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergTipuriDoc)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
