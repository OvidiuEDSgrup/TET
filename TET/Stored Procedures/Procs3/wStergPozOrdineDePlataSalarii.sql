
CREATE PROCEDURE wStergPozOrdineDePlataSalarii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE 
	@idPozOP INT, @mesaj VARCHAR(500), @docJurnal XML, @idOP INT, @docPoz XML, @ultim_stare varchar(200)

BEGIN TRY
	SET @idPozOP = @parXML.value('(/*/*/@idPozOP)[1]', 'int')
	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

	SELECT TOP 1 @ultim_stare = stare
		FROM JurnalOrdineDePlata
		WHERE idOP = @idOP
		ORDER BY data DESC

	if @ultim_stare <> 'Operat'
		raiserror('Documentul este intr-o stare care nu mai permite modificarea!',16, 1) 

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

	EXEC wIaPozOrdineDeplataSalarii @sesiune = @sesiune, @parXML = @docPoz
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergPozOrdineDePlataSalarii)'

	RAISERROR (@mesaj, 11, 1)
END CATCH

