
CREATE PROCEDURE wACTehnologiiInterventie @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @search VARCHAR(200)

SET @search = '%' + replace(@parXML.value('(/row/@searchText)[1]', 'varchar(200)'), ' ', '%') + '%'

SELECT TOP 100 RTRIM(cod) AS cod, RTRIM(denumire) AS denumire, 'Tip: ' + (
		CASE WHEN tip = 'P' THEN 'Produs' WHEN tip = 'R' THEN 'Reper' WHEN tip = 'S' THEN 'Serviciu' WHEN tip = 'M' THEN 'Multipla' WHEN tip = 'I' 
				THEN 'Interventie' END
		) AS info
FROM tehnologii
WHERE (
		cod LIKE @search
		OR Denumire LIKE @search
		)
	AND tip = 'I'
FOR XML raw, root('Date')
