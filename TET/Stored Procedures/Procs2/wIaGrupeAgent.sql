
CREATE PROCEDURE wIaGrupeAgent @sesiune VARCHAR(50), @parxml XML
AS
DECLARE @utilizator VARCHAR(100)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SELECT max(RTRIM(g.grupa)) AS cod, max(RTRIM(g.denumire)) AS denumire, ltrim(convert(VARCHAR(10), COUNT(1))) + ' articole' AS info
FROM grupe g
INNER JOIN proprietati p ON p.Tip = 'utilizator'
	AND p.Cod = @utilizator
	AND p.Cod_proprietate = 'OGRUPNOM'
	AND p.Valoare = g.Grupa
INNER JOIN nomencl ON nomencl.Grupa = g.Grupa
GROUP BY g.Grupa
FOR XML raw
