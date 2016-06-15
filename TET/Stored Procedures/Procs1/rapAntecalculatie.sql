
/** procedure pentru raportul Antecalculatiei (Antecalculatie.rdl)**/
CREATE PROCEDURE rapAntecalculatie @idAntec CHAR(20) 
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


SELECT (
		CASE WHEN pa.tip = 'M' THEN (CASE WHEN n.tip = 'P' THEN '2. semifabricate' WHEN n.cont LIKE '38%' THEN '3. ambalaje' ELSE '1. materiale' END
						) WHEN pa.tip = 'O' THEN '4.Operatii' ELSE '5. indirecte' END
		) AS dentip, rtrim(pa.tip) AS tip, rtrim(pa.cod) AS cod, convert(DECIMAL(15, 6), a.pret) pretantec, convert(VARCHAR(10), 
		convert(DECIMAL(15, 6), pa.cantitate)) AS cantitate, a.Data data, (
		CASE WHEN pa.tip = 'E'
				AND pa.cantitate > 0 THEN convert(DECIMAL(15, 6), pa.pret / pa.cantitate) ELSE convert(DECIMAL(15, 6), pa.pret) END
		) AS pret, (CASE WHEN pa.tip = 'M' THEN rtrim(n.denumire) WHEN pa.tip = 'O' THEN RTRIM(c.denumire) ELSE rtrim(e.descriere) END
		) AS denumire, (CASE WHEN pa.tip = 'E' THEN '-' WHEN pa.tip = 'M' THEN isnull(rtrim(n.um), '-') WHEN pa.tip = 'O' THEN isnull(rtrim(c.um), '-') END
		) AS um, rtrim(pt.cod) AS i_tehnologie, rtrim(n2.Denumire) AS dentehn, convert(FLOAT, ISNULL(e.procent, 1)) AS de_adunat
-- daca este procent sau componenta directa (material, oepartie, etc.) se aduna!          
FROM pozAntecalculatii pa
LEFT JOIN nomencl n ON pa.cod = n.Cod
	AND pa.tip = 'M'
LEFT JOIN catop c ON c.Cod = pa.cod
	AND pa.tip = 'O'
JOIN antecalculatii a ON pa.idp = a.idPoz
	AND a.idAntec = @idAntec
	AND pa.tip <> 'A'
LEFT JOIN pozTehnologii pt ON pt.cod = a.Cod
	AND pt.idp IS NULL
	AND pt.tip = 'T'
LEFT JOIN nomencl n2 ON n2.Cod = pt.cod
LEFT JOIN elemantec e ON e.element = pa.cod
	AND pa.tip = 'E'
ORDER BY 1, pa.id
