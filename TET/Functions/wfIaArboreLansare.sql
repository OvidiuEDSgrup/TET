
CREATE FUNCTION wfIaArboreLansare (@id INT)
RETURNS XML
AS
BEGIN
	IF EXISTS ( SELECT * FROM sysobjects WHERE NAME = 'wfIaArboreLansareSP' AND type = 'FN')
	BEGIN
		RETURN (SELECT dbo.wfIaArboreLansareSP(@id))
	END

	RETURN (
			SELECT (CASE WHEN pl.tip = 'O' THEN 'Operatie' 
						WHEN (pl.tip = 'M' AND n.tip = 'P') THEN 'Semifabricat' 
						WHEN pl.tip = 'R' THEN 'Reper' 
						ELSE 'Material' END) AS tip, 
					(CASE	WHEN pl.tip IN ('M', 'Z') THEN rtrim(n.denumire) 
							WHEN pl.tip = 'O' THEN rtrim(c.Denumire) 
							WHEN pl.tip = 'R' THEN RTRIM(isnull(t.denumire, pl.detalii.value('(/row/@denumire)[1]', 'varchar(20)'))) END) AS denumire, 
					(CASE	WHEN pl.tip IN ('M', 'Z') THEN rtrim(n.um) 
							WHEN pl.tip = 'O' THEN rtrim(c.um) END) AS um, 
					pl.id AS id, 
					rtrim(pl.cod) AS cod, 
					CONVERT(DECIMAL(18, 5), pl.cantitate) AS cantitate, 
					(CASE WHEN pl.tip = 'M' THEN 'MC' WHEN pl.tip = 'O' THEN 'OP' END) AS subtip, 
					dbo.wfIaArboreLansare(pl.id), 
					pl.detalii as detalii
			FROM pozLansari pl
			LEFT JOIN nomencl n ON n.Cod = pl.cod
			LEFT JOIN catop c ON c.Cod = pl.cod
			LEFT JOIN tehnologii t ON t.cod = pl.cod
			WHERE pl.tip IN ('M', 'O', 'R')
				AND pl.idp = @id
			ORDER BY pl.tip
			FOR XML raw, type
			)
END
