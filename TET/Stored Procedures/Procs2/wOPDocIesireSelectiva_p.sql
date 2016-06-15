
CREATE PROCEDURE wOPDocIesireSelectiva_p @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @mesaj varchar(max), @tip varchar(2), @numar varchar(20), @data datetime, @denlm varchar(300),
		@cantitate float, @lm varchar(20), @gestiune varchar(20), @cod varchar(20), @discount float,
		@stocTotal float, @sub varchar(10), @dencod varchar(200),
		@dengestiune varchar(200), @gestprim varchar(50), @tert varchar(50), @dentert varchar(300),
		@data_facturii datetime, @data_scadentei datetime, @comanda varchar(50), @factura varchar(20),
		@aviznefacturat bit, @punctlivrare varchar(50), @curs float, @valuta varchar(10), @pvaluta float,
		@contcorespondent varchar(40), @tiptva int,
		@detaliiAntet xml, @detaliiPozitii xml, @date xml
	
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT

	SET @tiptva = coalesce(@parXML.value('(/*/*/@tiptva)[1]', 'int'),@parXML.value('(/*/@tiptva)[1]', 'int') ,0)
	SET @tip = isnull(@parXML.value('(/*/*/@tip)[1]', 'varchar(2)'), '')
	SET @numar = isnull(@parXML.value('(/*/*/@numar)[1]', 'varchar(20)'), '')
	SET @data = isnull(@parXML.value('(/*/*/@data)[1]', 'datetime'), '')
	SET @lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(20)'), '')
	SET @cod = isnull(@parXML.value('(/*/*/@cod)[1]', 'varchar(20)'), '')
	SET @gestiune = isnull(@parXML.value('(/*/*/@gestiune)[1]', 'varchar(20)'), '')
	SET @cantitate = isnull(@parXML.value('(/*/*/@cantitate)[1]', 'float'), 0)
	SET @gestprim = isnull(@parXML.value('(/*/*/@gestprim)[1]', 'varchar(50)'), '')
	SET @tert = isnull(@parXML.value('(/*/*/@tert)[1]', 'varchar(50)'), '')
	SET @data_facturii = @parXML.value('(/*/*/@datafacturii)[1]', 'datetime')
	SET @data_scadentei = @parXML.value('(/*/*/@datascadentei)[1]', 'datetime')
	SET @comanda = isnull(@parXML.value('(/*/*/@comanda)[1]', 'varchar(50)'), '')
	SET @factura = isnull(@parXML.value('(/*/@factura)[1]', 'varchar(20)'), isnull(@parXML.value('(/*/*/@factura)[1]', 'varchar(20)'), ''))
	SET @aviznefacturat = isnull(@parXML.value('(/*/*/@aviznefacturat)[1]', 'bit'), 0)
	SET @punctlivrare = isnull(@parXML.value('(/*/*/@punctlivrare)[1]', 'varchar(50)'), '')
	SET @curs = isnull(isnull(@parXML.value('(/*/@curs)[1]', 'float'), @parXML.value('(/*/*/@curs)[1]', 'float')), 0)
	SET @valuta = isnull(isnull(@parXML.value('(/*/@valuta)[1]', 'varchar(3)'), @parXML.value('(/*/*/@valuta)[1]', 'varchar(3)')), '')
	SET @pvaluta = isnull(isnull(@parXML.value('(/*/@pvaluta)[1]', 'float'), @parXML.value('(/*/*/@pvaluta)[1]', 'float')), 0)
	SET @discount = isnull(@parXML.value('(/*/*/@discount)[1]', 'float'), 0)
	SET @contcorespondent = isnull(@parXML.value('(/*/*/@contcorespondent)[1]', 'varchar(40)'), @parXML.value('(/*/@contcorespondent)[1]', 'varchar(40)'))
	
	IF @parXML.exist('(/*/*/detaliiAntet/row)[1]') = 1
		SET @detaliiAntet = @parXML.query('(/*/*/detaliiAntet/row)[1]')

	IF @parXML.exist('(/*/*/detalii/row)[1]') = 1
		SET @detaliiPozitii = @parXML.query('(/*/*/detalii/row)[1]')

	IF OBJECT_ID('tempdb.dbo.#intrari') IS NOT NULL DROP TABLE #intrari

	IF @cod = '' OR @gestiune = ''
		RAISERROR('Completati codul si gestiunea!', 16, 1)
	
	IF @tip IN ('AP', 'AS') AND @tert = ''
		RAISERROR('Pentru avize se completeaza clientul!', 16, 1)

	IF ISNULL(@valuta, '') <> '' AND ISNULL(@curs, 0) = 0
		RAISERROR('Daca ati selectat o valuta, trebuie sa introduceti si cursul valutar!', 16, 1)

	declare @iesiriStocLaData int,	-- validare stocuri la data documentului
			@iesiriStocLaLuna int,	-- validare stocuri la luna documentului
			@dataStoc datetime 
	set @iesiriStocLaData=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='IESSLAZI'),0)
	set @iesiriStocLaLuna=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='IESLUNCRT'),0)
	set @dataStoc='2999-12-31'
	if @iesiriStocLaData=1 set @dataStoc=@Data 
	if @iesiriStocLaLuna=1 set @dataStoc=dbo.eom(@Data) 

	SET @stocTotal = 0
	SELECT @stocTotal = @stocTotal + s.Stoc
	FROM stocuri s
	WHERE s.Subunitate = @sub AND s.Cod = @cod AND s.Cod_gestiune = @gestiune
		AND ABS(s.Stoc) > 0.001
		AND s.data<=@dataStoc
	
	/** Validare stoc total */
	IF @stocTotal = 0
	BEGIN
		SET @mesaj = 'Codul introdus nu are stoc in gestiunea ' + @gestiune + '!'
		RAISERROR(@mesaj, 16, 1)
	END

	--> Daca nu se primeste suma, se va repartiza stocul total
	IF ISNULL(@cantitate, 0) = 0 AND @stocTotal > 0.001
		SET @cantitate = @stocTotal

	IF @cantitate > @stocTotal
	BEGIN
		SET @mesaj = 'Cantitatea introdusa este mai mare decat stocul din gestiunea ' + @gestiune + '!'
		RAISERROR(@mesaj, 16, 1)
	END

	SELECT ROW_NUMBER() OVER (ORDER BY p.Data) AS nr,
		RTRIM(p.tip) AS tipdoc_intrare, RTRIM(p.Numar) AS nrdoc_intrare, CONVERT(varchar(10), p.Data, 101) AS datadoc_intrare,
		RTRIM(s.Cod_intrare) AS cod_intrare, CONVERT(decimal(17,5), s.Pret) AS pret, CONVERT(decimal(15,2), s.Stoc) AS stoc,
		RTRIM(p.cont_de_stoc) AS contstoc, 0 AS selectat, CONVERT(float, 0) AS cantitate, CONVERT(FLOAT, 0) AS cumulat,
		RTRIM(p.Tert) AS tert, RTRIM(p.Factura) AS factura, rtrim(@contcorespondent) as contcorespondent
	INTO #intrari
	FROM stocuri s
	INNER JOIN pozdoc p ON p.idPozDoc = s.idIntrare
	WHERE s.Subunitate = @sub AND s.Cod = @cod AND s.Cod_gestiune = @gestiune
		AND ABS(s.Stoc) > 0.001
		AND s.data<=@dataStoc
	
	SELECT TOP 1 @denlm = RTRIM(lm.Denumire) FROM lm WHERE Cod = @lm
	SELECT TOP 1 @dengestiune = RTRIM(Denumire_gestiune) FROM gestiuni WHERE Cod_gestiune = @gestiune
	SELECT TOP 1 @dencod = RTRIM(Denumire) FROM nomencl WHERE Cod = @cod
	SELECT TOP 1 @dentert = RTRIM(Denumire) FROM terti WHERE Tert = @tert
	
	--> Calculam cumulatul la fiecare pozitie, bazat pe numarul de ordine primit de fiecare document de intrare (FIFO)
	UPDATE #intrari
	SET cumulat = cant_calculate.cumulat
	FROM
		(
			SELECT p2.nr, SUM(p1.stoc) as cumulat
			FROM #intrari p1, #intrari p2
			WHERE p1.nr < p2.nr
			GROUP BY p2.nr
		) AS cant_calculate
	WHERE cant_calculate.nr = #intrari.nr

	--> Calculam cantitatea pentru fiecare document
	UPDATE #intrari
	SET cantitate = (CASE WHEN cumulat + stoc <= @cantitate THEN stoc
		ELSE dbo.valoare_maxima(0, CONVERT(float, @cantitate) - CONVERT(float, cumulat), 0) END)

	--> updatam campul selectat in functie de cantitatile repartizate pe documente
	UPDATE #intrari
	SET selectat = 1
	WHERE ISNULL(ABS(cantitate), 0) > 0.001

	/** Date pentru form */
	select @date = 
	(
		SELECT @tip as tip, @numar as numar, convert(varchar(10), @data, 101) as data, @tiptva as tiptva,
			RTRIM(@lm) as lm, RTRIM(@denlm) as denlm, RTRIM(@gestprim) AS gestprim,
			CONVERT(decimal(15,3), @cantitate) as cantitate, convert(decimal(15,3), @cantitate) as cantitateFixa, 0 as diferenta,
			RTRIM(@gestiune) as gestiune, RTRIM(@dengestiune) as dengestiune, RTRIM(@cod) AS cod, RTRIM(@dencod) as dencod,
			RTRIM(@tert) AS tert, RTRIM(@dentert) AS dentert, @aviznefacturat AS aviznefacturat,
			RTRIM(@punctlivrare) AS punctlivrare, @data_facturii AS datafacturii, @data_scadentei AS datascadentei,
			RTRIM(@comanda) AS comanda, CONVERT(decimal(17,5), @pvaluta) AS pvaluta, CONVERT(decimal(17,5), @discount) AS discount,
			@detaliiAntet AS detalii
		FOR XML RAW, ROOT('Date')
	)

	ALTER TABLE #intrari ADD detalii xml
	UPDATE #intrari SET detalii = @detaliiPozitii

	if exists (select 1 from sysobjects where type='P' and name='wOPDocIesireSelectiva_pSP')
		exec wOPDocIesireSelectiva_pSP @date output

	select @date

	/** Date pentru grid */
	SELECT (   
		SELECT
			p.nr,
			p.tipdoc_intrare,
			p.nrdoc_intrare,
			p.datadoc_intrare,
			p.cod_intrare,
			p.pret,
			p.stoc,
			p.contstoc,
			CONVERT(int, selectat) AS selectat,
			CONVERT(decimal(17,2), p.cantitate) AS cantitate,
			CONVERT(decimal(17,2), @cantitate) AS cantitateFixaPoz,
			CONVERT(decimal(12,5), @curs) AS curs,
			@valuta AS valuta,
			CONVERT(decimal(17,5), @pvaluta) AS pvaluta,
			rtrim(p.contcorespondent) as contcorespondent,
			p.detalii AS detalii
		FROM #intrari p
		ORDER BY p.nr
		FOR XML RAW, TYPE  
		)  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')

	SELECT '1' AS areDetaliiXml FOR XML RAW, ROOT('Mesaje')

END TRY

BEGIN CATCH
	select  '1' as inchideFereastra for xml raw, root('Mesaje')
	set @mesaj = error_message() + ' (' + object_name(@@procid) + ')'
	raiserror(@mesaj,16,1)
END CATCH
