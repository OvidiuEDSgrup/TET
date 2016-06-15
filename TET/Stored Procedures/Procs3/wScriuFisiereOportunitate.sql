
CREATE PROCEDURE wScriuFisiereOportunitate @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idOportunitate INT, @observatii VARCHAR(2000), @idFisier INT, @fisier VARCHAR(2000), @mesaje VARCHAR(500)

	SET @idOportunitate = @parXML.value('(/*/@idOportunitate)[1]', 'int')
	SET @idFisier = @parXML.value('(/*/@idFisier)[1]', 'int')
	SET @fisier = @parXML.value('(/*/@fisier)[1]', 'varchar(2000)')
	SET @observatii = @parXML.value('(/*/@observatii)[1]', 'varchar(2000)')

	IF @idOportunitate IS NULL
		RAISERROR ('Nu s-a putut identitica oportunitatea', 11, 1)

	IF @idFisier IS NULL
	BEGIN
		INSERT INTO FisiereOportunitati(idOportunitate, fisier, observatii)
		SELECT @idOportunitate, @fisier, @observatii
	END
END TRY
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
