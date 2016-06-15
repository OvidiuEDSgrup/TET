
CREATE FUNCTION wfIaArboreElemAntec (@id INT, @parinte VARCHAR(20))
RETURNS XML
AS
BEGIN
	RETURN 
	(
		SELECT 
			RTRIM(e.element) AS cod, RTRIM(e.descriere) AS _grupare, 
			(CASE WHEN e.procent = 1 THEN '( ' + RTRIM(e.formula) + ' )*' + CONVERT(VARCHAR(5),p.cantitate) ELSE RTRIM(e.formula) END) AS pret,
			convert(DECIMAL(12, 5), p.pret) AS valoare, CONVERT(VARCHAR(6), p.cantitate * 100) + '%' AS cantitate, 
			(CASE WHEN e.procent = 1 THEN 'E' ELSE '' END) AS subtip, (CASE WHEN procent = 1 THEN 'Procent' ELSE '-' END) AS um, 'E' AS tip, 
			convert(DECIMAL(12, 5), p.pret / a.curs) AS valuta, (RTRIM(e.descriere) + ' (' + rtrim(p.cod) + ')') AS denumireCod, 
			dbo.wfIaArboreElemAntec(@id, e.element), RTRIM(descriere) AS denumire, @id AS idAntec, p.id AS 	id
		FROM pozAntecalculatii p
		INNER JOIN antecalculatii a ON p.idp = a.idPoz AND p.tip = 'E' AND a.idAntec = @id
		INNER JOIN elemantec e ON e.element = p.cod AND e.element_parinte = @parinte AND p.idp = a.idPoz
		ORDER BY element
		FOR XML raw, type
	)
END
