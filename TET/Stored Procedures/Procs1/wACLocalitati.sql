
--***
CREATE PROCEDURE wACLocalitati @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(80), @judet VARCHAR(3)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), ' ', '%') + '%'
--select @parXML
SET @judet = @parXML.value('(/row/@judet)[1]', 'varchar(3)')
SET @searchText = REPLACE(@searchText, ' ', '%')

select @judet
SELECT TOP 100 rtrim(l.cod_oras) AS cod, rtrim(l.oras) AS denumire, 
		rtrim(CASE WHEN l.extern = 0 THEN 'Judet: ' + ISNULL(j.denumire, '') 
				ELSE 'Tara: ' + ISNULL(t.denumire, '') END) AS info
FROM localitati l
LEFT OUTER JOIN judete j ON l.extern = 0
	AND j.cod_judet = l.cod_judet
	
LEFT OUTER JOIN tari t ON l.extern = 1
	AND t.cod_tara = l.cod_judet
WHERE l.oras LIKE '%' + @searchText + '%' 
	AND (
		j.cod_judet = @judet
		OR isnull(@judet,'')=''
		OR LEN(RTRIM(@judet))>2 -- la salarii judetul este introdus in clar -> nu este de natura codificarii auto
		)
ORDER BY 2
FOR XML raw
