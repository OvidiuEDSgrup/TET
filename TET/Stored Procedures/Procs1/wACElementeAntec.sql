
CREATE PROCEDURE wACElementeAntec @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'

SELECT '-' AS cod, '-' AS denumire, '-' AS info

UNION ALL

SELECT rtrim(element) AS cod, RTRIM(descriere) AS denumire, RTRIM(Descriere) AS info
FROM elemantec
WHERE element NOT IN ('MAN', 'MAT')
	AND element LIKE @searchText
	OR Descriere LIKE @searchText
FOR XML raw, root('Date')
