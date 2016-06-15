
--***
CREATE PROCEDURE wACOperatii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100)

SET @searchText = replace(isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%')

SELECT TOP 100 rtrim(cod) AS cod, convert(varchar(10),convert(decimal(15,2),tarif))+'/' + rtrim(UM) AS info, rtrim(denumire) AS denumire
FROM catop c
WHERE (
		cod LIKE @searchText + '%'
		OR denumire LIKE '%' + @searchText + '%'
		)
ORDER BY cod
FOR XML raw, root('Date')


