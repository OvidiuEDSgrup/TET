
--***
CREATE PROCEDURE wIaOperatii @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wIaOperatiiSP'
			AND type = 'P'
		)
	EXEC wIaOperatiiSP @sesiune, @parXML
ELSE
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @filtruCod VARCHAR(100), @filtruDenumire VARCHAR(100), @filtruTip VARCHAR(100), @filtruTarifJ FLOAT, @filtruTarifS 
		FLOAT, @filtruUM VARCHAR(100), @filtruCategorie VARCHAR(100), @areNormaTimp BIT

	SET @filtruCod = '%' + isnull(@parXML.value('(/row/@f_cod)[1]', 'varchar(100)'), '') + '%'
	SET @filtruDenumire = '%' + isnull(@parXML.value('(/row/@f_denumire)[1]', 'varchar(100)'), '') + '%'
	SET @filtruTip = '%' + isnull(@parXML.value('(/row/@f_tipoperatie)[1]', 'varchar(100)'), '') + '%'
	SET @filtruTarifJ = isnull(@parXML.value('(/row/@f_tarifj)[1]', 'float'), - 99999999)
	SET @filtruTarifS = isnull(@parXML.value('(/row/@f_tarifs)[1]', 'float'), 999999999)
	SET @filtruUM = '%' + isnull(@parXML.value('(/row/@f_UM)[1]', 'varchar(100)'), '') + '%'
	SET @filtruCategorie = '%' + isnull(@parXML.value('(/row/@f_categorie)[1]', 'varchar(100)'), '') + '%'

	IF OBJECT_ID('tempdb..#wCatop') IS NOT NULL
		DROP TABLE #wCatop

	CREATE TABLE #catop100 (cod VARCHAR(20) PRIMARY KEY)

	INSERT #catop100
	SELECT TOP 100 rtrim(c.Cod) AS cod
	FROM catop c
	WHERE c.Cod LIKE @filtruCod
		AND c.Denumire LIKE @filtruDenumire
		AND c.Tip_operatie LIKE @filtruTip
		AND c.Tarif BETWEEN @filtruTarifJ
			AND @filtruTarifS
		AND c.UM LIKE @filtruUM
		AND c.Categorie LIKE @filtruCategorie

	SELECT rtrim(c.Cod) AS cod, RTRIM(c.Denumire) AS denumire, rtrim(c.Tip_operatie) AS tipoperatie, convert(DECIMAL(12, 5), c.Tarif
		) AS tarif, RTRIM(c.UM) AS UM, RTRIM(c.Categorie) AS categorie
	INTO #wCatop
	FROM catop c
	INNER JOIN #catop100 c1 ON c.cod = c1.cod
	ORDER BY patindex(@filtruDenumire, c.Denumire)

	IF EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'catop'
				AND sc.NAME = 'Norma_timp'
			)
	BEGIN
		SET @areNormaTimp = 1

		ALTER TABLE #wCatop ADD normatimp DECIMAL(12, 2)

		UPDATE #wCatop
		SET normatimp = convert(DECIMAL(12, 2), isnull(c.Norma_timp, c.Numar_persoane))
		FROM catop c
		INNER JOIN #catop100 cc ON cc.cod = c.cod
		WHERE c.cod = #wCatop.cod
	END
	ELSE
		SET @areNormaTimp = 0

	SELECT *
	FROM #wCatop
	FOR XML raw, root('Date')

	SELECT @areNormaTimp AS areNormaTimpDecimal
	FOR XML raw, root('Mesaje')
	

	DROP TABLE #catop100
END
