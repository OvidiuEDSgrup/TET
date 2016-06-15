
CREATE PROCEDURE wOPGenerareFormularComanda @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idContract INT, @mesaj VARCHAR(400)

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')

	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identifica contractul pentru care se doreste generarea formularului!', 11, 1
				)

	SET @parXML.modify('insert attribute nrform {"comanda"} into (/*[1])')

	EXEC wTipFormular @sesiune = @sesiune, @parXML = @parXML
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareFormularComanda)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
