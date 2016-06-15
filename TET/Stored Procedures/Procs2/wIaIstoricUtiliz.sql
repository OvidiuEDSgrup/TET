
CREATE PROCEDURE wIaIstoricUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @f_bd VARCHAR(20), @f_tip VARCHAR(20), @datajos DATETIME, @datasus DATETIME, @data XML

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @f_bd = '%' + isnull(@parXML.value('(/row/@f_bd)[1]', 'varchar(20)'), '') + '%'
SET @f_tip = '%' + isnull(@parXML.value('(/row/@f_tip)[1]', 'varchar(50)'), '') + '%'
SET @datajos = @parXML.value('(/row/@datajos)[1]', 'varchar(50)')
SET @datasus = @parXML.value('(/row/@datasus)[1]', 'varchar(50)')
--SELECT RTRIM(l1.token) AS token, RTRIM(l1.BD) AS bd, CONVERT(VARCHAR(10), l1.data, 101) + ' ' + convert(VARCHAR, l1.data, 8) AS data, (CASE WHEN l1.tip = 'I' THEN 'Intrare' ELSE 'Iesire' END
--		) AS tip, (CASE WHEN l1.tip = 'E' THEN '#FF0000' ELSE '#008000' END) AS culoare, DATEDIFF(minute, l1.data, l2.data) AS 
--	durata
--FROM ASiSRIA..logUtilizatori l1
--LEFT JOIN ASiSRIA..logUtilizatori l2 ON l1.token = l2.token
--	AND l1.tip = 'I'
--	AND l2.tip = 'E'
--WHERE l1.utilizator = @utilizator
--	AND (CASE WHEN l1.tip = 'I' THEN 'Intrare' ELSE 'Iesire' END) LIKE @f_tip
--	AND l1.bd LIKE @f_bd
--	AND l1.data BETWEEN @datajos
--		AND @datasus
----AND l1.bd = DB_NAME()
--ORDER BY token, data
--FOR XML raw, root('Date')

if exists (select 1 from utilizatori u where u.ID=@utilizator and u.Marca='GRUP')
	raiserror('Acesta este un grup! Nu exista istoric pe grupuri!',16,1)

SET @data = (
		SELECT utr.token AS token, utr.BD AS bd, max(isnull(DATEDIFF(minute, utr.data, utr2.data), 0)) AS data, (
				SELECT CONVERT(VARCHAR(10), data, 103) + ' ' + convert(VARCHAR(80), data, 8) AS data, (CASE WHEN tip = 'I' THEN 'Intrare' ELSE 'Iesire' END
						) AS token, bd, (CASE WHEN tip = 'E' THEN '#FF0000' ELSE '#008000' END) AS culoare
				FROM ASiSRIA..logUtilizatori
				WHERE token = utr.token
					AND (CASE WHEN tip = 'I' THEN 'Intrare' ELSE 'Iesire' END) LIKE @f_tip
				ORDER BY tip DESC
				FOR XML raw, type
				)
		FROM asisria..logUtilizatori utr
		LEFT OUTER JOIN asisria..logUtilizatori utr2 ON utr.token = utr2.token
			AND utr.tip = 'I'
			AND utr2.tip = 'E'
		WHERE utr.utilizator = @utilizator
			AND utr.data BETWEEN @datajos
				AND @datasus
			AND utr.BD LIKE @f_bd
		GROUP BY utr.token, utr.BD
		ORDER BY MAX(utr.data)
		FOR XML raw, root('Ierarhie'), type
		)

IF @data IS NOT NULL
	SET @data.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

SELECT @data
FOR XML path('Date')
