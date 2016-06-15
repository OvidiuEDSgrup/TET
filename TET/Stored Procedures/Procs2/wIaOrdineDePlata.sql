
CREATE PROCEDURE wIaOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
DECLARE 
	@utilizator VARCHAR(100), @idOP INT, @f_cont VARCHAR(50), @f_dencont VARCHAR(100), @f_explicatii VARCHAR(2000), @f_stare VARCHAR(2000), 
	@datajos DATETIME, @datasus DATETIME, @tip varchar(20)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @f_cont = @parXML.value('(/*/@f_cont)[1]', 'varchar(50)')
SET @f_dencont = @parXML.value('(/*/@f_dencont)[1]', 'varchar(100)')
SET @f_explicatii = @parXML.value('(/*/@f_explicatii)[1]', 'varchar(2000)')
SET @f_stare = @parXML.value('(/*/@f_stare)[1]', 'varchar(2000)')
SET @tip= @parXML.value('(/*/@tip)[1]', 'varchar(20)')
SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')
SET @datajos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'), '01/01/1910')
SET @datasus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'), '01/01/2110')

IF OBJECT_ID('tempdb..#stareOrdineDePlata') IS NOT NULL
	DROP TABLE #stareOrdineDePlata
IF OBJECT_ID('tempdb..#LMOrdineDePlata') IS NOT NULL
	DROP TABLE #LMOrdineDePlata

	/** Inseram intr-o tabela temporara ultima stare a ordinelor de plata **/
	SELECT * 
	INTO #stareOrdineDePlata 
	FROM (
		SELECT 
			idOP, stare, RANK() OVER (PARTITION BY idOP ORDER BY Data DESC,f.idJurnalOP DESC) as ordine
		FROM JurnalOrdineDePlata f 
		) a
	WHERE Ordine=1

	/** Inseram intr-o tabela temporara locul de munca al ordinelor de plata,
		daca se lucreaza cu proprietatea LOCMUNCA pt. a function mai rapid filtrarea **/
	SELECT idOP, f.detalii.value('/row[1]/@lm','VARCHAR(20)') as lm
	INTO #LMOrdineDePlata 
	FROM OrdineDePlata f 
	WHERE f.data BETWEEN @datajos AND @datasus

	SELECT 
		ant.idOP AS idOP, CONVERT(VARCHAR(10), ant.data, 101) data, RTRIM(ant.cont_contabil) AS cont, 
		rtrim(c.Denumire_cont) AS dencont,
		RTRIM(ant.tip) AS tip, RTRIM(ant.Explicatii) AS explicatii, ant.detalii, isnull(so.stare,'') as stare, 
		(CASE isnull(so.stare,'') WHEN 'Finalizat' THEN '#0000FF' WHEN 'Banca' THEN '#007700' WHEN 'Generat' THEN '#808080' ELSE '#000000' end) as culoare,
		(CASE WHEN isnull(so.stare,'') = 'Generat' THEN 1 ELSE 0 end) as _nemodificabil,
		convert(decimal(15,2), isnull(sm.suma,0)) suma
	FROM OrdineDePlata ant
	LEFT JOIN (
			SELECT idOP, isnull(SUM(suma),0) suma
			FROM PozOrdineDePlata where stare='1'
			GROUP BY idOP
			) sm ON ant.idOP = sm.idOP
	INNER JOIN conturi c
		ON c.Cont = ant.cont_contabil
	LEFT JOIN #stareOrdineDePlata so 
		ON so.idOP=ant.idOP
	LEFT JOIN #LMOrdineDePlata lm
		ON lm.idOP=ant.idOP
	LEFT OUTER JOIN LMFiltrare lu 
		ON lu.utilizator=@utilizator and lu.cod=lm.lm
	WHERE (
			(@idOP IS NULL and 	ant.tip=@tip )
			OR ant.idOP = @idOP
			)
		AND (
			@f_dencont IS NULL
			OR c.Denumire_cont LIKE '%' + @f_dencont + '%'
			)
		AND (
			@f_cont IS NULL
			OR ant.cont_contabil LIKE '%' + @f_cont + '%'
			)
		AND (
			@f_explicatii IS NULL
			OR ant.explicatii LIKE '%' + @f_explicatii + '%'
			)
		AND (
			@f_stare IS NULL
			OR isnull(so.stare,'') LIKE '%' + @f_stare + '%'
			)
		AND ant.data BETWEEN @datajos
			AND @datasus
		AND (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null) 
	FOR XML raw, root('Date')

	SELECT '1' AS areDetaliiXml
	FOR XML raw, root('Mesaje')
