
CREATE PROCEDURE wACJurnale @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @tipAsociere VARCHAR(2)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'

SELECT rtrim(jurnal) AS cod, rtrim(descriere) AS denumire, 'Utilizator: ' + rtrim(utilizator) AS info
FROM jurnale
WHERE jurnal LIKE @searchText
	OR descriere LIKE @searchText
FOR XML raw, root('Date')
