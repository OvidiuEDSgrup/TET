
/** Autocomplete cu prioritati de la 1 la 5 */
CREATE PROCEDURE wACPrioritatiCRM @sesiune varchar(50), @parXML xml
AS

	SELECT 1 AS cod, 1 AS denumire UNION
	SELECT 2 AS cod, 2 AS denumire UNION
	SELECT 3 AS cod, 3 AS denumire UNION
	SELECT 4 AS cod, 4 AS denumire UNION
	SELECT 5 AS cod, 5 AS denumire
	FOR XML RAW
