
CREATE PROCEDURE wIaPozPlanificareLansari @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idParinte INT, @comanda VARCHAR(20), @doc XML

SET @comanda = ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), '')
SET @idParinte = (
		SELECT id
		FROM pozLansari
		WHERE cod = @comanda
			AND tip = 'L'
		)
SET @doc = (
		SELECT p.id AS id, '(' + RTRIM(p.cod) + ') ' + rtrim(c.denumire) AS denumire, RTRIM(p.cod) AS codOperatie, CONVERT(DECIMAL(10, 2)
				, p.cantitate) AS cantitate, rtrim(pp.cod) AS parinte, (
				SELECT 'Comanda ' + RTRIM(pl.comanda) AS denumire, convert(DECIMAL(10, 2), pl.cantitate) AS cantitate, 'MO' AS subtip
					, RTRIM(rs.descriere) AS resursa, RTRIM(pl.resursa) AS codResursa, idOp AS idOp, pl.id AS idPlanif, convert(CHAR(
							10), dataStart, 101) AS dataStart, convert(CHAR(10), dataStop, 101) AS dataStop, RTRIM(p.cod) AS 
					codOperatie, RTRIM(pl.oraStart) as oraStart, RTRIM(pl.oraStop) as oraStop
				FROM planificare pl
				INNER JOIN resurse rs ON rs.id = pl.resursa
				WHERE idOp = p.id
				FOR XML raw, type
				)
		FROM pozLansari p
		JOIN pozLansari pp ON pp.id = p.idp
			AND p.parinteTop = @idParinte
			AND p.tip = 'O'
		LEFT JOIN catop c ON c.cod = p.cod
		FOR XML raw, root('Ierarhie')
		)

IF @doc IS NOT NULL
	SET @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

SELECT @doc
FOR XML path('Date')
