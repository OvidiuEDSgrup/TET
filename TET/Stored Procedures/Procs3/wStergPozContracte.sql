
CREATE PROCEDURE wStergPozContracte @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idContract INT, @idPozContract INT, @mesaj VARCHAR(400), @docIaPoz XML, @stare int, @tipContract varchar(2)

	SET @idPozContract = @parXML.value('(/*/*/@idPozContract)[1]', 'int')
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')
	SET @tipContract= @parXML.value('(/*/@tip)[1]', 'varchar(2)')

	if (select top 1 modificabil from StariContracte where tipContract=@tipContract and stare=@stare) <> 1
		raiserror('Documentul este intr-o stare care nu permite stergerea pozitiilor!',11,1)

	DELETE
	FROM PozContracte
	WHERE idPozContract = @idPozContract

	SET @docIaPoz = (
			SELECT @idContract idContract
			FOR XML raw
			)

	EXEC wIaPozContracte @sesiune = @sesiune, @parXML = @parXML
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergPozContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
