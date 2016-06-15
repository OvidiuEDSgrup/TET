
CREATE PROCEDURE wIaPlanificareLansari @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @fltCod VARCHAR(20), @fltComanda VARCHAR(16), @fltDescriere VARCHAR(50), @fltDataJos DATETIME, @fltDataSus DATETIME, 
	@comanda VARCHAR(20), @fltCodProdus VARCHAR(50), @fltProdus VARCHAR(50), @fltTert VARCHAR(50)

SET @fltComanda = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_comanda)[1]', 'varchar(16)'), '%'), ' ', '%') + '%'
SET @fltCodProdus = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_cod_produs)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @fltProdus = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_produs)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @fltTert = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_tert)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @comanda = '%' + REPLACE(ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), '%'), ' ', '%') + '%'
SET @fltDataJos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1900')
SET @fltDataSus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/2050')

SELECT TOP 100 
	RTRIM(pt.cod) AS comanda, RTRIM(c.descriere) AS descriere, RTRIM(produs.cod) AS cod, 
	(CASE c.Tip_comanda WHEN 'P' THEN RTRIM(n.Denumire) WHEN 'X' THEN rtrim(tt.denumire) END) AS denprodus, 
	convert(varCHAR(10), c.data_lansarii, 101) AS dataLansare, convert(CHAR(10), c.data_inchiderii, 101) AS 
	dataInchidere, convert(DECIMAL(10, 2), pt.cantitate) AS cantitate, RTRIM(n.um) AS um, isnull(RTRIM(c.Tip_comanda), 'S') AS tipL, 
	isnull(RTRIM(t.Denumire), 'intern') AS tert, 
	(CASE c.starea_comenzii when 'I' THEN '#808080' when 'L' then '#0000FF' when 'B' then '#FF0000' else '#000000' END) AS 	culoare, 
	(CASE c.starea_comenzii when 'L' THEN 0 else 1 END) AS 	_nemodificabil
FROM pozLansari pt
INNER JOIN pozTehnologii produs ON produs.id = pt.idp
	AND pt.tip = 'L'
	AND produs.tip = 'T'
INNER JOIN tehnologii tt ON tt.cod = produs.cod
LEFT JOIN comenzi c ON pt.cod = c.Comanda
LEFT JOIN nomencl n ON TT.codnomencl = n.Cod
LEFT JOIN terti t ON t.Tert = c.Beneficiar
WHERE pt.cod LIKE @fltComanda
	AND (CASE c.Tip_comanda WHEN 'P' THEN RTRIM(n.Denumire) WHEN 'X' THEN rtrim(tt.denumire) END) LIKE @fltProdus
	AND (
		n.cod IS NULL
		OR n.cod LIKE @fltCodProdus
		)
	AND isnull(c.data_lansarii, @fltDataJos) BETWEEN @fltDataJos
		AND @fltDataSus
	AND pt.cod LIKE @comanda
	AND isnull(RTRIM(t.Denumire), 'intern') LIKE @fltTert
ORDER BY c.Comanda DESC
FOR XML raw, root('Date')
