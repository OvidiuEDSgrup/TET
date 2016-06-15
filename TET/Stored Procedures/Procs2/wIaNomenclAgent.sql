
CREATE PROCEDURE wIaNomenclAgent @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(100)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SELECT rtrim(nomencl.cod) cod, MAX(rtrim(nomencl.denumire)) denumire, isnull(MAX(convert(DECIMAL(15, 2), nomencl.Pret_stoc)), 0) 
	pret, max(rtrim(nomencl.Grupa)) AS grupa, convert(VARCHAR(20), MAX(nomencl.pret_stoc)) + ' lei / ' + max(RTRIM(nomencl.um)) AS 
	info
FROM nomencl
INNER JOIN proprietati p ON p.Tip = 'utilizator'
	AND p.Cod = @utilizator
	AND p.Cod_proprietate = 'OGRUPNOM'
	AND p.Valoare = nomencl.grupa
WHERE nomencl.Tip <> 'U'
GROUP BY nomencl.cod
FOR XML raw
