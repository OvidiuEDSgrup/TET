
CREATE PROCEDURE wOPImprimareFacturiContracte @sesiune varchar(50) = NULL, @parXML xml = NULL, @idRulare int = 0
AS

IF @idRulare = 0 -- procedura e apelata din frame
BEGIN
	EXEC wOperatieLunga @sesiune = @sesiune, @parXML = @parXML, @procedura = 'wOPImprimareFacturiContracte'
	RETURN
END

BEGIN TRY
	
	DECLARE @utilizator varchar(50), @datajos datetime, @datasus datetime,
		@factura varchar(20), @idContract int, @formular varchar(50), @tipContract varchar(2),
		@caleFormular varchar(500), @nrFacturi int, @mesajeXml xml

	SELECT @parXML = p.parXML, @sesiune = p.sesiune
	FROM asisria.dbo.ProceduriDeRulat p
	WHERE p.idRulare = @idRulare

	SELECT @datajos = @parXML.value('(/parametri/@datajos)[1]', 'datetime'),
		@datasus = @parXML.value('(/parametri/@datasus)[1]', 'datetime'),
		@factura = ISNULL(@parXML.value('(/parametri/@factura)[1]', 'varchar(20)'), ''),
		@idContract = ISNULL(@parXML.value('(/parametri/@idContract)[1]', 'int'), 0),
		@tipContract = @parXML.value('(/parametri/@tip)[1]', 'varchar(2)'),
		@formular = ISNULL(@parXML.value('(/parametri/@formular)[1]', 'varchar(50)'), '')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	IF @formular = ''
		RAISERROR('Alegeti unul din formularele asociate facturilor!', 16, 1)

	SELECT @caleFormular = RTRIM(CLWhere) FROM antform WHERE Numar_formular = @formular

	IF OBJECT_ID('tempdb.dbo.#facturi') IS NOT NULL DROP TABLE #facturi

	SELECT DISTINCT p.Subunitate, p.Tip, p.Numar, p.Data, p.Factura INTO #facturi
	FROM pozdoc p
	INNER JOIN LegaturiContracte lc ON lc.idPozDoc = p.idPozDoc
	INNER JOIN PozContracte pc ON pc.idPozContract = lc.idPozContract
	INNER JOIN Contracte c ON c.idContract = pc.idContract
	WHERE c.tip = @tipContract
		AND (p.Data BETWEEN @datajos AND @datasus)
		AND (@idContract = 0 OR c.idContract = @idContract)
		AND (@factura = '' OR p.Factura = @factura)

	IF (SELECT COUNT(1) FROM #facturi) = 0
		RAISERROR('Nu exista contracte facturate in aceste conditii!', 16, 1)
	
	/** Daca numarul de facturi in functie de tip, numar si data este 1, nu se mai face concatenarea si, in cazul acesta,
		va trebui sa afisam factura generata. */
	SELECT @nrFacturi = COUNT(*) FROM #facturi

	/** Imprimare facturi concatenate */
	DECLARE @facturaJos varchar(50), @facturaSus varchar(50), @crs cursor, @numar varchar(50), @data_facturii datetime,
	@tert varchar(50), @tipdoc varchar(20), @cmdShellCommand nvarchar(4000), @cTextSelect nvarchar(4000),
	@dentert varchar(200), @numeFisier varchar(2000), @counter int, @pathPdfConcat varchar(5000), @numeFisierParametru varchar(5000),
	@numeTabel varchar(500), @nServer varchar(500), @xml xml, @cale varchar(max)

	SELECT @cale = RTRIM(val_alfanumerica) FROM par WHERE Tip_parametru = 'AR' AND Parametru = 'CALEFORM'

	/** In cazul in care CALEFORM nu are backslash la sfarsit, punem ca sa se poata afisa PDF-ul in browser. */
	IF RIGHT(@cale, 1) <> '\'
		SELECT @cale = @cale + '\'

	IF OBJECT_ID('tempdb..#fisiere') IS NOT NULL DROP TABLE #fisiere
	CREATE TABLE #fisiere (numeFisier varchar(500))

	UPDATE p
		SET statusText = 'Generez facturile PDF...'
	FROM asisria.dbo.ProceduriDeRulat p
	WHERE p.idRulare = @idRulare

	/** Identificare facturi */
	SELECT @facturaJos = MIN(RTRIM(Factura)), @facturaSus = MAX(RTRIM(Factura))
	FROM #facturi

	SET @crs = CURSOR LOCAL FAST_FORWARD FOR
	SELECT d.Tip, d.Numar, d.Data, d.Cod_tert, ROW_NUMBER() OVER (ORDER BY d.Numar)
	FROM doc d
	INNER JOIN #facturi p ON p.Subunitate = d.Subunitate AND p.Tip = d.Tip AND p.Numar = d.Numar AND p.Data = d.Data
	WHERE d.Factura between @facturaJos and @facturaSus
	ORDER BY d.Numar
	
	OPEN @crs
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM @crs INTO @tipdoc, @numar, @data_facturii, @tert, @counter
		IF (@@FETCH_STATUS <> 0) 
			BREAK 
		
		SET @dentert = ISNULL((SELECT TOP 1 RTRIM(denumire) FROM terti WHERE tert = @tert AND subunitate = '1'), '')
		SET @dentert = RTRIM((CASE WHEN CHARINDEX(' ', @dentert) > 0 THEN LEFT(@dentert, CHARINDEX(' ', @dentert)) ELSE @dentert END))
		
		SET @numeFisier = @dentert + '_' + RTRIM(@numar)

		UPDATE p
			SET statusText = 'Generez formularul ' + CONVERT(varchar, @counter) + ' din ' + CONVERT(varchar, @nrFacturi)
		FROM asisria.dbo.ProceduriDeRulat p
		WHERE p.idRulare = @idRulare

		SET @xml = (
			SELECT @numeFisier AS numeFisier, @caleFormular AS caleRaport, DB_NAME() AS BD, @tipdoc AS tip,
				@numar AS numar, convert(varchar(10), @data_facturii, 120) AS data, 1 AS nrExemplare,
				(CASE WHEN @nrFacturi = 1 THEN 0 ELSE 1 END) AS faraMesaje
				-- 0 = o singura factura ==> se va afisa aceasta factura; altfel, se va face concatenarea.
			FOR XML RAW
		)
		EXEC wExportaRaport @sesiune = @sesiune, @parXML = @xml

		INSERT INTO #fisiere(numeFisier) VALUES (@numeFisier + '.pdf')
	END

	CLOSE @crs
	DEALLOCATE @crs

	IF @nrFacturi > 1
	BEGIN
		UPDATE p
			SET statusText = 'Concatenez facturile intr-un PDF mai mare...'
		FROM asisria.dbo.ProceduriDeRulat p
		WHERE p.idRulare = @idRulare

		IF OBJECT_ID('tempdb.dbo.#raspCmdShell') IS NOT NULL DROP TABLE #raspCmdShell
		CREATE TABLE #raspCmdShell (raspunsCmdShell varchar(max))

		SET @pathPdfConcat = REPLACE(@cale, '\formulare\', '\mobria\')
		SET @numeTabel = '##rap_' + REPLACE(NEWID(), '-', '')
		SET @numeFisierParametru =
			'FacturiContracte' + LEFT(REPLACE(CONVERT(varchar(100), NEWID()), '-', ''), 7)

		SET @cTextSelect = 'IF OBJECT_ID(''tempdb.dbo.' + @numeTabel + ''') IS NOT NULL DROP TABLE ' + @numeTabel
		EXEC sp_executesql @statement = @cTextSelect
	
		SET @cTextSelect = 'CREATE TABLE ' + @numeTabel + ' (valoare varchar(max))
		INSERT INTO ' + @numeTabel + '(valoare)
		SELECT ''' + @cale + ''' + numeFisier FROM #fisiere'
		EXEC sp_executesql @statement = @cTextSelect
	
		IF OBJECT_ID('tempdb.dbo.#fisiere') IS NOT NULL DROP TABLE #fisiere
	
		SELECT @nServer = CONVERT(varchar(1000), SERVERPROPERTY('ServerName')),
			@cmdShellCommand = 'bcp "select valoare from ' + @numeTabel + '" queryout "' + @cale + @numeFisierParametru + '.txt" -T -c -t -C UTF-8 -S' + @nServer
	
		INSERT #raspCmdShell
		EXEC xp_cmdshell @cmdShellCommand

		-- formare comanda pt generare raport
		SET @cmdShellCommand = '' + @pathPdfConcat + 'PdfConcat.exe "' + @cale + @numeFisierParametru + '.txt" "' + @cale + @numeFisierParametru + '.pdf"'

		--select @cmdShellCommand
		INSERT into #raspCmdShell
		EXEC xp_cmdshell @statement = @cmdShellCommand
	
		SET @cTextSelect = 'IF OBJECT_ID(''tempdb.dbo.' + @numeTabel + ''') IS NOT NULL DROP TABLE ' + @numeTabel
		EXEC sp_executesql @statement = @cTextSelect

		/** Afisam formularul concatenat */
		set @mesajeXML=(SELECT @numeFisierParametru + '.pdf' AS fisier, 'wTipFormular' AS numeProcedura FOR XML RAW, ROOT('Mesaje'))

		IF OBJECT_ID('tempdb.dbo.#raspCmdShell') IS NOT NULL DROP TABLE #raspCmdShell
	END
	ELSE
		SET @mesajeXML = (SELECT @numeFisierParametru + '.pdf' AS fisier, 'wTipFormular' AS numeProcedura FOR XML RAW, ROOT('Mesaje'))

	UPDATE p
		SET statusText = 'Finalizare operatie', mesaje = @mesajeXml
	FROM asisria.dbo.ProceduriDeRulat p
	WHERE p.idRulare = @idRulare

	SELECT @mesajeXML

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
