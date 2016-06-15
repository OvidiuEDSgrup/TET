
CREATE PROCEDURE wIaJurnalOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idOP INT, @datasus DATETIME, @datajos DATETIME, @utilizator VARCHAR(100)

SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')
SET @utilizator = @parXML.value('(/*/@f_utilizator)[1]', 'varchar(100)')
SET @datajos = isnull(@parXML.value('(/*/datajos)[1]', 'datetime'), '01/01/1910')
SET @datasus = isnull(@parXML.value('(/*/datasus)[1]', 'datetime'), '01/01/2110')

SELECT jo.idJurnalOP idJurnalOP, jo.idOP idOP, convert(VARCHAR(10), jo.data, 103) + ' ' + convert(VARCHAR(8), jo.data, 108) data, RTRIM
	(jo.operatie) operatie, RTRIM(jo.stare) stare, RTRIM(jo.utilizator) utilizator
FROM JurnalOrdineDePlata jo
WHERE jo.idOp = @idOP
	AND CONVERT(DATE, data) BETWEEN @datajos
		AND @datasus
	AND (
		@utilizator IS NULL
		OR jo.utilizator LIKE '%' + @utilizator + '%' 
		)
FOR XML raw, root('Date')
