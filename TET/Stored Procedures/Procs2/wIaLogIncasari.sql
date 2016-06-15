
CREATE PROCEDURE wIaLogIncasari @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @f_utilizator VARCHAR(50), @f_numar VARCHAR(50), @f_tert VARCHAR(20), @f_dentert VARCHAR(100), @datasus DATETIME, @datajos 
	DATETIME

SET @f_utilizator = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_utilizator)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @f_numar = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_numar)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @f_tert = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_tert)[1]', 'varchar(20)'), '%'), ' ', '%') + '%'
SET @f_dentert = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_dentert)[1]', 'varchar(100)'), '%'), ' ', '%') + '%'
SET @datajos = @parXML.value('(/row/@datajos)[1]', 'datetime')
SET @datasus = @parXML.value('(/row/@datasus)[1]', 'datetime')

SELECT RTRIM(ds.utilizator) AS utilizator, RTRIM(ds.cod) AS numar, RTRIM(ds.cod2) AS serie, CONVERT(VARCHAR(10), ds.data, 101) AS data
	, RTRIM(ds.tert) AS tert, RTRIM(t.denumire) AS dentert, RTRIM(STATUS) AS STATUS, convert(DECIMAL(10, 3), suma) AS suma, (CASE WHEN STATUS = 'ok' THEN '#00FF00' ELSE '#FF0000' END
		) AS culoare, ds.id AS id
FROM dateSincronizare ds
INNER JOIN terti t ON t.Tert = ds.tert
	AND t.tert LIKE @f_tert
	AND t.Denumire LIKE @f_dentert
	AND ds.cod LIKE @f_numar
	AND ds.utilizator LIKE @f_utilizator
WHERE ds.tip = 'S'
	AND convert(DATE, ds.data) BETWEEN @datajos
		AND @datasus
FOR XML raw, root('Date')
