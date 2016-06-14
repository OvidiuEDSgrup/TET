IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'yso_wOPSchimbStareContract_p'
		)
	DROP PROCEDURE yso_wOPSchimbStareContract_p
GO

CREATE PROCEDURE yso_wOPSchimbStareContract_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idContract INT, @stare INT, @mesaj VARCHAR(500), @docJurnal XML
		, @numar varchar(20)

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @numar = @parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')

	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identificare comanda/contractul ', 11, 1)

	IF @stare > 1
		RAISERROR ('Comanda selectata este trecuta de starea "Definitiv"', 11, 1)

	select stare=@stare, numar=@numar
	for xml raw, ROOT('Date')
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wOPSchimbStareContract_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH
