
CREATE PROCEDURE wOPAlocareToateRap @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @alocat BIT, @utilizator VARCHAR(100)

SET @alocat = @parXML.value('(/row/@alocat)[1]', 'bit')
SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(100)')

DELETE
FROM webConfigRapoarte
WHERE utilizator = @utilizator

IF @alocat = 1
BEGIN
	INSERT INTO webConfigRapoarte (caleRaport, utilizator)
	SELECT convert(VARCHAR(500), path), @utilizator
	FROM ReportServer..CATALOG
	where ParentID is not null
END
