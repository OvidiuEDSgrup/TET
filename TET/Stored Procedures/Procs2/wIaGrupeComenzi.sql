--***
CREATE PROCEDURE wIaGrupeComenzi @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @mesajeroare VARCHAR(500), @fltGrupa VARCHAR(100), @fltCont VARCHAR(50), @areDetalii BIT

	SELECT @fltGrupa = ISNULL(@parXML.value('(/row/@fltGrupa)[1]', 'varchar(100)'), '')

	IF OBJECT_ID('tempdb..#wGrupeComenzi') IS NOT NULL
		DROP TABLE #wGrupeComenzi

	SELECT rtrim(g.Tip_comanda) + ' - ' + CASE g.Tip_comanda when 'P' then 'Productie terti' when 'R' then 'Servicii terti' 
		when 'X' then 'Auxiliara' when 'T' then 'Transport' when 'S' then 'Semifabricat' when 'V' then 'Servicii auxiliare'
		when 'C' then 'Productie cuplata' when 'L' then 'Regie loc munca' when 'G' then 'Regie generala' when 'A' then 'Anexa'
		when 'Z' then 'Aprovizionare' when 'D' then 'Desfacere' else '' END AS dentipcom, rtrim(g.Tip_comanda) AS tipcom, 
		rtrim(g.grupa) AS grupa, rtrim(g.Denumire_grupa) AS denumire
	INTO #wGrupeComenzi
	FROM grcom g
	WHERE rtrim(g.Denumire_grupa) + '(' + rtrim(g.grupa) + ')' LIKE '%' + isnull(@fltGrupa, '') + '%'
	ORDER BY grupa

	IF EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'grcom' AND sc.NAME = 'detalii')
	BEGIN
		SET @areDetalii = 1
		ALTER TABLE #wGrupeComenzi ADD detalii XML
		UPDATE #wGrupeComenzi SET detalii = g.detalii
			FROM grcom g
			WHERE g.Grupa = #wGrupeComenzi.grupa and g.Tip_comanda = #wGrupeComenzi.tipcom 
	END
	ELSE
		SET @areDetalii = 0

	SELECT *
	FROM #wGrupeComenzi
	FOR XML raw, root('Date')

	SELECT @areDetalii AS areDetaliiXml
	FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesajeroare = ERROR_MESSAGE() + '(wIaGrupeComenzi)'
	RAISERROR (@mesajeroare, 11, 1)
END CATCH
