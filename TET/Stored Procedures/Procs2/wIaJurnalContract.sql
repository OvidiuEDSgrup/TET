
CREATE PROCEDURE wIaJurnalContract @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@f_stare INT, @f_denstare VARCHAR(10), @idContract INT

	SELECT
		@f_denstare = '%' + @parXML.value('(/*/@f_denstare)[1]', 'varchar(20)') + '%',
		@f_stare = @parXML.value('(/*/@f_stare)[1]', 'int'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int')

	SELECT 
		convert(VARCHAR(10), jc.data, 103) + ' ' + convert(VARCHAR(8), jc.data, 108) AS data, jc.stare AS stare, rtrim(sc.denumire) AS denstare, 
		rtrim(jc.explicatii) AS explicatii, RTRIM(jc.utilizator) AS utilizator,jc.idJurnal idJurnal,
		jc.detalii detalii, jc.detalii dateXML
	FROM JurnalContracte jc
	INNER JOIN Contracte c ON c.idContract = @idContract AND c.idContract = jc.idContract
	INNER JOIN StariContracte sc ON sc.tipContract = c.tip 	AND sc.stare = jc.stare
	WHERE 
		(@f_stare IS NULL OR jc.stare = @f_stare) AND 
		(@f_denstare IS NULL OR sc.denumire LIKE @f_denstare)
	ORDER BY jc.data
	FOR XML raw, root('Date')
