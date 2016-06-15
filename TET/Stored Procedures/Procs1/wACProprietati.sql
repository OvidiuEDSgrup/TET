
CREATE PROCEDURE wACProprietati @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100)

SET @searchText = '%' + REPLACE(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%') + '%'

SELECT RTRIM(cpr.cod_proprietate) AS cod, RTRIM(cpr.descriere) AS denumire, 'Validare: ' + (
		CASE WHEN cpr.Validare = '0' THEN 'Fara' WHEN cpr.Validare = '2' THEN 'Catalog' WHEN cpr.Validare = '1' THEN 'Lista' ELSE 'Compusa' 
			END
		) AS info
FROM catproprietati cpr
WHERE cpr.descriere LIKE @searchText
	OR cpr.cod_proprietate LIKE @searchText
FOR XML raw, root('Date')
