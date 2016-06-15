
CREATE PROCEDURE wStergAsocieriPlaja @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idPlaja INT, @tip VARCHAR(1), @cod VARCHAR(20), @mesaj varchar(500)

	SET @idPlaja = @parXML.value('(/*/@idPlaja)[1]', 'int')
	SET @tip = @parXML.value('(/*/*/@tipasociere)[1]', 'varchar(1)')
	SET @cod = @parXML.value('(/*/*/@cod)[1]', 'varchar(20)')

	DELETE
	FROM asocieredocfiscale
	WHERE id = @idPlaja
		AND tipasociere = @tip
		AND cod = @cod
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergAsocieriPlaja)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
