
CREATE PROCEDURE yso_wOPSchimbStareContract @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idContract INT, @stare INT, @mesaj VARCHAR(500), @docJurnal XML, @tip varchar(2)

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')

	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identificare comanda/contractul ', 11, 1)

	IF @stare > 1
		RAISERROR ('Comanda selectata nu se poate in aceasta stare!', 11, 1)

	SET @docJurnal = (
			SELECT @idContract idContract, @stare stare, GETDATE() AS data, RTRIM(st.denumire) AS explicatii
			FROM StariContracte st where st.tipContract=@tip and st.stare=@stare
			FOR XML raw
			)

	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wOPSchimbStareContract)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
