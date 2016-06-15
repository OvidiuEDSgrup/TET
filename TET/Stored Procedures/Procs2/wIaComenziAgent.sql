
CREATE PROCEDURE wIaComenziAgent @sesiune VARCHAR(50), @parxml XML
AS
DECLARE @utilizator VARCHAR(100), @lm VARCHAR(50)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @lm = isnull(dbo.wfProprietateUtilizator('LOCMUNCA', @utilizator), '')

SELECT rtrim(c.numar) AS cod, rtrim(c.Tert) AS tert, '' AS factura, RTRIM(t.denumire) AS denumire, CONVERT(VARCHAR(
			10), c.data, 101) AS data, 'Pozitii: ' + LTRIM(str(count(pc.cantitate))) AS info, --(rtrim(sc.stare)) AS stare, 
		(SELECT RTRIM(numar) AS comanda, RTRIM(cod) AS cod, CONVERT(DECIMAL(15, 2), cantitate) AS cantitate
		FROM pozcontracte
		WHERE c.Tip = 'CL' AND c.idContract = idContract
		FOR XML raw, type
		)
FROM contracte c
LEFT JOIN pozcontracte pc ON  c.idContract = pc.idContract
LEFT JOIN terti t ON  t.tert = c.Tert
LEFT JOIN infotert it ON it.subunitate = t.subunitate AND it.tert = t.tert AND it.identificator = ''
outer apply (select top 1 stare from jurnalcontracte j where j.idContract=c.idContract order by data desc) sc
WHERE isnull(c.tert, '') <> ''
	AND it.loc_munca = @lm
	AND sc.Stare = '0'
GROUP BY  c.Tip, c.Tert, c.Punct_livrare, c.numar,c.idContract, c.Explicatii, t.Denumire, c.Data,rtrim(sc.stare)
FOR XML raw



