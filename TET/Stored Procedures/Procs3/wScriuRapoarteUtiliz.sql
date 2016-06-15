
CREATE PROCEDURE wScriuRapoarteUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @update BIT, @alocat BIT, @id UNIQUEIDENTIFIER, @cale VARCHAR(500), @utilizator VARCHAR(100)

SET @update = isnull(@parXML.value('(/row/@update)[1]', 'bit'), 0)
SET @alocat = @parXML.value('(/row/@alocat)[1]', 'bit')
SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(100)')
SET @cale = @parXML.value('(/row/@caleraport)[1]', 'varchar(500)')

IF @update = 1
BEGIN
	DELETE
	FROM webConfigRapoarte
	WHERE caleRaport LIKE rtrim(@cale) + '%'
		AND utilizator = @utilizator

	IF @alocat = 1
	BEGIN
		INSERT INTO webConfigRapoarte (caleRaport, utilizator)
		SELECT convert(VARCHAR(500), path), @utilizator
		FROM ReportServer..CATALOG
		WHERE Path LIKE (convert(VARCHAR(500), @cale + '%') collate SQL_Latin1_General_CP1_CI_AS)
	END
END
ELSE
	SELECT 
		'Nu exista posibilitatea de a adauga rapoarte noi prin aceasta macheta! Toate rapoartele din baza de date se afla in tabel!' 
		textMesaj, 'Notificare' AS titluMesaj
	FOR XML raw, root('Mesaje')
