
CREATE PROCEDURE wScriuFisiereDocument @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@idFisier int, @tip varchar(2), @numar varchar(20), @data datetime,
		@fisier varchar(2000), @observatii varchar(2000), @update bit

	SELECT
		@idFisier = @parXML.value('(/row/@idFisier)[1]', 'int'),
		@tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@numar = @parXML.value('(/row/@numar)[1]', 'varchar(20)'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@fisier = ISNULL(@parXML.value('(/row/@fisier)[1]', 'varchar(2000)'), ''),
		@observatii = ISNULL(@parXML.value('(/row/@observatii)[1]', 'varchar(2000)'), ''),
		@update = ISNULL(@parXML.value('(/row/@update)[1]', 'bit'), 0)

	--IF @fisier = ''
	--	RAISERROR('Fisierul nu a fost selectat.', 16, 1)

	IF (@update = 1)
	BEGIN
		UPDATE FisiereDocument
		SET fisier = @fisier,
			observatii = @observatii
		WHERE idFisier = @idFisier
	END
	ELSE
	BEGIN
		INSERT INTO FisiereDocument(tip, numar, data, fisier, observatii)
		SELECT @tip, RTRIM(@numar), @data, RTRIM(@fisier), RTRIM(@observatii)
	END

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
