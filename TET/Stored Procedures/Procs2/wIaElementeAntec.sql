
CREATE PROCEDURE wIaElementeAntec @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @fltDescriere VARCHAR(50), @fltCod VARCHAR(20), @fltProcentSus FLOAT, @fltProcentJos FLOAT, @fltParinte VARCHAR(20)

SET @fltDescriere = '%' + replace(ISNULL(@parXML.value('(/row/@f_descriere)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @fltCod = '%' + replace(ISNULL(@parXML.value('(/row/@f_cod)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @fltParinte = '%' + replace(ISNULL(@parXML.value('(/row/@f_parinte)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'
SET @fltProcentJos = ISNULL(@parXML.value('(/row/@f_procentJos)[1]', 'float'), 0)
SET @fltProcentSus = ISNULL(@parXML.value('(/row/@f_procentSus)[1]', 'float'), 10000)

SELECT RTRIM(element) AS cod, RTRIM(descriere) AS descriere, RTRIM(formula) AS n_formula, (CASE WHEN procent = 1 THEN procent ELSE 0 END
		) AS n_procent, (CASE WHEN procent = 1 THEN '(' + RTRIM(formula) + ')*' + CONVERT(VARCHAR(20), valoare_implicita) ELSE RTRIM(formula) END
		) AS formula, (CASE WHEN procent = 1 THEN 'Da' ELSE 'Nu' END) AS procent, (CASE WHEN procent = 1 THEN convert(VARCHAR(10), valoare_implicita * 100) + '%' ELSE '-' END
		) AS valoare, (CASE WHEN element_parinte IS NULL THEN '-' ELSE rtrim(element_parinte) END) AS parinte, pas
FROM elemantec
WHERE element LIKE @fltCod
	AND Descriere LIKE @fltDescriere
	AND ISNULL(valoare_implicita * 100, 0) BETWEEN @fltProcentJos
		AND @fltProcentSus
	AND isnull(element_parinte, '%') LIKE @fltParinte
ORDER BY pas
FOR XML raw, root('Date')
