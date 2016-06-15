--***
CREATE PROCEDURE wIaGrupeTerti @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @mesajeroare VARCHAR(500), @fltGrupa VARCHAR(100), @areDetalii BIT

	SELECT @fltGrupa = ISNULL(@parXML.value('(/row/@fltGrupa)[1]', 'varchar(100)'), '')

	IF OBJECT_ID('tempdb..#wGrupeTerti') IS NOT NULL
		DROP TABLE #wGrupeTerti

	SELECT rtrim(g.grupa) AS grupa, rtrim(g.Denumire) AS denumire, CONVERT(decimal(17,2), Discount_acordat) as discount
	INTO #wGrupeTerti
	FROM gterti g
	WHERE rtrim(g.Denumire) + '(' + rtrim(g.grupa) + ')' LIKE '%' + isnull(@fltGrupa, '') + '%'
	ORDER BY grupa

	IF EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'gterti' AND sc.NAME = 'detalii')
	BEGIN
		SET @areDetalii = 1
		ALTER TABLE #wGrupeTerti ADD detalii XML
		UPDATE #wGrupeTerti SET detalii = g.detalii
			FROM gterti g
			WHERE g.Grupa = #wGrupeTerti.grupa 
	END
	ELSE
		SET @areDetalii = 0

	SELECT *
	FROM #wGrupeTerti
	FOR XML raw, root('Date')

	SELECT @areDetalii AS areDetaliiXml
	FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesajeroare = ERROR_MESSAGE() + '(wIaGrupeTerti)'
	RAISERROR (@mesajeroare, 11, 1)
END CATCH
