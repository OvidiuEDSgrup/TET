
CREATE PROCEDURE wOPPreluareSalariiInOrdineDePlata_p @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idOP INT, @luna INT, @an INT, @lunainch INT, @anulinch INT, @data DATETIME, @stare VARCHAR(20)

SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')
SET @data = @parXML.value('(/*/@data)[1]', 'datetime')

SELECT TOP 1 @stare = stare
	FROM JurnalOrdineDePlata
	WHERE idOP = @idOP
	ORDER BY data DESC

SET @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
SET @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
SELECT @luna=(case when @lunainch=12 then 1 else @lunainch+1 end),
@an=(case when @lunainch=12 then @anulInch+1 else @anulinch end)

SELECT
	 @luna luna, @an an,  '' cont, '' banca, '' explicatii, convert(char(10),dbo.BOM(@data),101) datajos, convert(char(10),dbo.EOM(@data),101) datasus
FOR XML raw, root('Date')

IF @stare='Definitiv'
	RAISERROR ('Nu se pot prelua pozitii pe un ordin de plata aflat in starea "Definitiv"!', 16, 1)
