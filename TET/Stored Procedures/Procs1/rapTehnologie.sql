
CREATE PROCEDURE rapTehnologie @idTehnologie INT, @peNivele INT
AS
WITH arbore (id, ordine, cod, idParinte, idReal, cant_i, lm, tip, cantitate, nivel, parinte)
AS (
	SELECT p.id AS id, isnull(convert(DECIMAL(10, 6), p.ordine_o), 0) AS ordine, p.cod, p.idp, p.id AS idReal, ISNULL(convert(DECIMAL(
					16, 6), p.cantitate_i), 0) AS cant_i, rtrim(p.resursa) AS lm, p.tip AS tip, convert(DECIMAL(16, 6), 1) AS cantitate, 
		1 AS nivel, p.cod AS parinte
	FROM poztehnologii AS p
	WHERE p.id = @idTehnologie
		AND p.idp IS NULL
		AND p.tip = 'T'
	
	UNION ALL
	
	SELECT (
			CASE WHEN p.tip IN ('M', 'R')
					AND @peNivele = 1 THEN isnull((
								SELECT id
								FROM poztehnologii
								WHERE tip = 'T'
									AND cod = p.cod
								), p.id) ELSE p.id END
			) AS id, isnull(convert(DECIMAL(10, 6), p.ordine_o), 0) AS ordine, p.cod, p.idp, p.id AS idReal, ISNULL(convert(DECIMAL(16
					, 6), p.cantitate_i), 0) AS cant_i, rtrim(p.resursa) AS lm, p.tip AS tip, convert(DECIMAL(16, 6), p.cantitate * a.
			cantitate) AS cantitate, a.nivel + 1 AS nivel, p.cod AS parinte
	FROM poztehnologii AS p
	JOIN arbore AS a ON a.id = p.parinteTop
		--AND p.tip NOT IN ('A', 'L', 'O', 'Z')
	)
SELECT rtrim(a.cod) AS cod, max(a.tip) AS tip, max((
		CASE WHEN a.tip IN ('M', 'Z') THEN rtrim(n.denumire) WHEN a.tip = 'O' THEN rtrim(c.Denumire) WHEN a.tip IN ('R', 'T'
					) THEN RTRIM(t.denumire) END
		)) AS denumire, sum(convert(DECIMAL(15, 6), a.cantitate)) AS cantitate, max((CASE WHEN a.tip = 'M' THEN rtrim(g.denumire) ELSE 'Operatii' END
		)) AS dentip, max(CASE WHEN a.tip IN ('M', 'Z') THEN rtrim(n.um) WHEN a.tip = 'O' THEN rtrim(c.um) END) AS 
	um, max(RTRIM(pt.cod)) AS i_tehnologie, max(RTRIM(n2.denumire)) AS dentehn, max(a.nivel), max(a.parinte)
FROM arbore a
LEFT JOIN nomencl n ON a.tip = 'M'
	AND n.cod = a.cod
LEFT JOIN grupe g ON g.Grupa = n.Grupa
LEFT JOIN catop c ON c.Cod = a.cod
LEFT JOIN tehnologii t ON a.tip = 'T'
	AND a.cod = t.cod
LEFT JOIN pozTehnologii pt ON pt.id = @idTehnologie
LEFT JOIN nomencl n2 ON n2.Cod = pt.cod
WHERE a.id <> @idTehnologie
GROUP BY  a.cod
ORDER BY max(a.id)