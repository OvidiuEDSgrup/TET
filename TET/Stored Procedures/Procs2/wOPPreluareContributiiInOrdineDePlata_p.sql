
CREATE PROCEDURE wOPPreluareContributiiInOrdineDePlata_p @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(100), @idOP INT, @cont varchar(20), @lunainch INT, @anulinch INT, @datainch datetime, 
	@data DATETIME, @datajos DATETIME, @datasus DATETIME, @stare VARCHAR(20), 
	@tertImpozit VARCHAR(20), @dentertImpozit VARCHAR(100), @tertCAS VARCHAR(20), @dentertCAS VARCHAR(100)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')
SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')

SELECT TOP 1 @stare = stare
	FROM JurnalOrdineDePlata
	WHERE idOP = @idOP
	ORDER BY data DESC

SET @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
SET @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
SET @datainch=dbo.EOM(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
SET @dataJos=DateADD(day,1,@datainch)
SET @dataSus=dbo.EOM(@datajos)

IF OBJECT_ID('tempdb..#dateOP') IS NOT NULL DROP TABLE #dateOP

SELECT o.idOP, po.tert, po.detalii.value('/row[1]/@tipsuma','VARCHAR(20)') as tip_suma, o.detalii.value('/row[1]/@lm','VARCHAR(20)') as lm
INTO #dateOP
FROM PozOrdineDePlata po
	LEFT OUTER JOIN OrdineDePlata o ON o.idOP=po.idOP
WHERE o.Tip='CS'
	AND (po.detalii.value('/row[1]/@tipsuma','VARCHAR(20)')='Impozit' or po.detalii.value('/row[1]/@tipsuma','VARCHAR(20)')='CAS')

SELECT top 1 @tertImpozit=MAX((CASE WHEN tip_suma='Impozit' THEN op.Tert ELSE @tertImpozit END))
	,@dentertImpozit=MAX((CASE WHEN tip_suma='Impozit' THEN t.Denumire ELSE @dentertImpozit END))
	,@tertCAS=MAX((CASE WHEN tip_suma='CAS' THEN op.Tert ELSE @tertCAS END))
	,@dentertCAS=MAX((CASE WHEN tip_suma='CAS' THEN t.Denumire ELSE @dentertCAS END))
FROM #dateOP op
	LEFT OUTER JOIN LMFiltrare lu ON lu.utilizator=@utilizator and lu.cod=op.lm
	LEFT OUTER JOIN terti t ON t.Tert=op.Tert
WHERE (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)  
GROUP BY op.idOP
ORDER BY op.idOP DESC

SELECT
	convert(char(10),@datajos,101) datajos, convert(char(10),@datasus,101) datasus, 
	convert(char(10),@data,101) data, @cont cont, 
	@tertImpozit tertimp, @tertCAS tertcas, @dentertImpozit dentertimp, @dentertCAS dentertcas, '' explicatii
FOR XML raw, root('Date')

IF @stare='Definitiv'
	RAISERROR ('Nu se pot prelua pozitii pe un ordin de plata aflat in starea "Definitiv"!', 16, 1)
