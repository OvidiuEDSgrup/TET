
CREATE PROCEDURE wScriuFisiereAtasate @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idContract INT, @observatii VARCHAR(2000), @idFisier INT, @fisier VARCHAR(2000), @mesaje VARCHAR(500), @idPozContract INT

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @idPozContract = @parXML.value('(/*/@idPozContract)[1]', 'int')
	SET @idFisier = @parXML.value('(/*/@idFisier)[1]', 'int')
	SET @fisier = @parXML.value('(/*/@fisier)[1]', 'varchar(2000)')
	SET @observatii = @parXML.value('(/*/@observatii)[1]', 'varchar(2000)')

	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identitica contractul', 11, 1)

	IF @idFisier IS NULL
	BEGIN
		INSERT INTO FisiereContract (idContract,idPozContract ,fisier, observatii)
		SELECT @idContract,@idPozContract, @fisier, @observatii
	END
END TRY

BEGIN CATCH
	SET @mesaje = ERROR_MESSAGE() + ' (wScriuFisiereAtasate)'

	RAISERROR (@mesaje, 11, 1)
END CATCH
