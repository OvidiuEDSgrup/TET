--drop proc yso.predariPacheteTmp 
ALTER PROC yso.predariPachete 
--DECLARE 
@cHostId char(10)
AS 
DECLARE @cTextSelect nvarchar(max)
--SET @cHostId='11140'

SELECT DISTINCT pa.Subunitate, pa.Numar, pa.Data, pa.Cod, pa.Cod_intrare
INTO #codIntrarePachete
FROM pozdoc pa 
	INNER JOIN avnefac a ON a.Terminal=@cHostId AND a.Subunitate=pa.Subunitate AND a.Tip=pa.Tip AND a.Data=pa.Data
		AND a.Numar=pa.Numar --AND a.Cod_gestiune='' AND a.Contractul=''
WHERE a.Tip='AP'

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #codIntrarePachete (Subunitate, cod, cod_intrare)

--drop table yso.predariPacheteTmp 
IF OBJECT_ID('yso.predariPacheteTmp') IS NULL
BEGIN
	--SET @cTextSelect=''
	CREATE TABLE yso.predariPacheteTmp 
		(Terminal char(10),
		Subunitate char(9),
		NumarAviz char(8),
		DataAviz datetime,
		Numar char(8),
		Data datetime)
	CREATE UNIQUE NONCLUSTERED INDEX Unic ON predariPacheteTmp (Terminal, Subunitate, Numar, Data)
	CREATE UNIQUE NONCLUSTERED INDEX Aviz ON predariPacheteTmp (Terminal, Subunitate, Numar, Data, NumarAviz, DataAviz)
END

DELETE yso.predariPacheteTmp
WHERE Terminal=@cHostId

INSERT yso.predariPacheteTmp
SELECT DISTINCT @cHostId, pp.Subunitate, pa.Numar, pa.Data, pp.numar, pp.data 
FROM pozdoc pp 
	INNER JOIN #codIntrarePachete pa ON pp.Subunitate=pa.Subunitate AND pa.Cod=pp.Cod AND pa.Cod_intrare=pp.Cod_intrare
WHERE pp.Tip='PP'
--select * from #codIntrarePachete 
DROP TABLE #codIntrarePachete

GO

--EXEC yso.predariPachete '11140'