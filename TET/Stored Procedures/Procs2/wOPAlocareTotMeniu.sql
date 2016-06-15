
CREATE PROCEDURE wOPAlocareTotMeniu @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @sterg BIT, @adaug BIT, @modific BIT, @formulare BIT, @operatii BIT, @drepturi VARCHAR(5), @alocat BIT

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @sterg = @parXML.value('(/row/@dsterg)[1]', 'bit')
SET @adaug = @parXML.value('(/row/@dadaug)[1]', 'bit')
SET @modific = @parXML.value('(/row/@dmodific)[1]', 'bit')
SET @formulare = @parXML.value('(/row/@dformulare)[1]', 'bit')
SET @operatii = @parXML.value('(/row/@doperatii)[1]', 'bit')
SET @alocat = @parXML.value('(/row/@alocat)[1]', 'bit')

SELECT @drepturi = (CASE WHEN @sterg = 1 THEN 'S' ELSE '' END) + (CASE WHEN @adaug = 1 THEN 'A' ELSE '' END) + (CASE WHEN @modific = 1 THEN 'M' ELSE '' END
		) + (CASE WHEN @formulare = 1 THEN 'F' ELSE '' END) + (CASE WHEN @operatii = 1 THEN 'O' ELSE '' END)

DELETE
FROM webConfigMeniuUtiliz
WHERE IdUtilizator = @utilizator

IF @alocat = 1
BEGIN
	INSERT INTO webConfigMeniuUtiliz (IdUtilizator, IdMeniu, Drepturi, Meniu)
	SELECT DISTINCT @utilizator, nrordine, @drepturi, meniu
	FROM webconfigmeniu
END
