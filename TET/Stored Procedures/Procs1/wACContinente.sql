
/** Autocomplete continente */
CREATE PROCEDURE wACContinente @sesiune varchar(50), @parXML xml
AS
	DECLARE @continente table (cod varchar(1), denumire varchar(100))
	INSERT INTO @continente (cod, denumire)
	SELECT '', '' UNION ALL
	SELECT 'A', 'Asia' UNION ALL
	SELECT 'E', 'Europa' UNION ALL
	SELECT 'F', 'Africa' UNION ALL
	SELECT 'N', 'America de Nord' UNION ALL
	SELECT 'S', 'America de Sud' UNION ALL
	SELECT 'U', 'Australia'

	SELECT cod, denumire
	FROM @continente
	FOR XML RAW
