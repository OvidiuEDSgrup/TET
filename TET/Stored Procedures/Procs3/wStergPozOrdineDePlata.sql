
CREATE PROCEDURE wStergPozOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idPozOP INT, @mesaj VARCHAR(500), @docJurnal XML, @idOP INT, @docPoz XML

BEGIN TRY
	SET @idPozOP = @parXML.value('(/*/*/@idPozOP)[1]', 'int')
	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

	DELETE
	FROM PozOrdineDePlata
	WHERE idPozOP = @idPozOP

	SET @docJurnal = (
			SELECT @idOP idOP, 'Stergere pozitie' operatie
			FOR XML raw
			)

	EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @docJurnal

	SET @docPoz = (
			SELECT @idOP idOP
			FOR XML raw
			)

	EXEC wIaPozOrdineDeplata @sesiune = @sesiune, @parXML = @docPoz
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergPozOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
