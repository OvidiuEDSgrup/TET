
CREATE PROCEDURE wIaOperatiiResursa @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @codRes VARCHAR(16), @tipRes VARCHAR(16), @idRes INT

SET @codRes = ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(16)'), '')
SET @tipRes = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(16)'), '')
SET @idRes = ISNULL(@parXML.value('(/row/@id)[1]', 'int'), 0)

SELECT RTRIM(r.cod) AS cod, (
		CASE 
			WHEN c.UM <> 'H'
				THEN convert(DECIMAL(10, 2), r.capacitate)
			ELSE '1'
			END
		) AS capacitate, RTRIM(c.denumire) AS denumire, RTRIM(c.um) AS um, id AS id
FROM catop c, OpResurse r
WHERE r.idRes = @idRes
	AND c.Cod = r.cod
FOR XML raw, root('Date')
