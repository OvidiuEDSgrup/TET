
/** Procedura Mobile de aducere sarcini CRM, filtrate pe agentul curent */
CREATE PROCEDURE wmIaSarciniCRM @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@utilizator varchar(50), @lista_lm bit = 0, @lista_sarcini xml,
		@adaugare xml, @searchText varchar(200), @activitati xml, @tert varchar(50), @idPotential int, @xml xml

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	select	@searchText = NULLIF(@parXML.value('(/row/@searchText)[1]', 'varchar(200)'), ''),
			@tert = ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(200)'), ''),
			@idPotential = @parXML.value('(/*/@idPotential)[1]', 'int')
	
	IF @idPotential IS NULL AND @tert <> ''
	BEGIN
		SET @xml = (SELECT @tert AS tert, 1 AS cu_adaugare FOR XML RAW)
		EXEC wIaIdPotentialDinTert @sesiune = @sesiune, @parXML = @xml OUTPUT
		SET @idPotential = NULLIF(@xml.value('(/*/@idPotential)[1]', 'int'), 0)
	END

	IF OBJECT_ID('tempdb..#activitati') IS NOT NULL
		DROP TABLE #activitati

	IF EXISTS (SELECT 1 FROM LMFiltrare l WHERE l.utilizator = @utilizator)
		SET @lista_lm = 1

	SET @adaugare =
	(
		SELECT 
			'adaugare' AS cod, 'Adauga sarcina' AS denumire, '0x0000ff' AS culoare,
			'assets/Imagini/Meniu/AdaugProdus32.png' AS poza, dbo.f_wmIaForm('SRCRM') AS form,
			'wmScriuSarciniCRM' AS procdetalii, 'D' AS tipdetalii, @idPotential AS idPotential, 
			(SELECT RTRIM(p.denumire) FROM Potentiali p WHERE p.idPotential = @idPotential) AS denPotential
		FOR XML RAW, TYPE
	)

	/** Punem in tabela temporara activitatile filtrate pe searchText, iar in select-ul principal 
		aducem, pe langa sarcinile cu filtrul respectiv, si activitatile filtrate din cadrul altor sarcini. */
	SELECT
		*
	INTO #activitati
	FROM ActivitatiCRM a
	WHERE note LIKE '%' + @searchText + '%'
	AND (@idPotential IS NULL OR a.idPotential = @idPotential)

	/** Luam sarcinile */
	SET @lista_sarcini =
	(
		SELECT top 100
			RTRIM(sc.tip_sarcina) AS cod,
			RTRIM(sc.descriere) AS denumire,
			'Data: ' + CONVERT(varchar(10), sc.data, 103) + ' Termen: ' + CONVERT(varchar(10), sc.termen, 103) AS info,
			sc.idSarcina AS sarcina,
			RTRIM(sc.descriere) AS descriere,
			CONVERT(varchar(10), sc.data, 103) AS data,
			CONVERT(varchar(10), sc.termen, 103) AS termen,
			sc.prioritate AS prioritate,
			RTRIM(sc.tip_sarcina) AS tip_sarcina, RTRIM(sc.tip_sarcina) AS dentip_sarcina,
			RTRIM(sc.idPotential) AS tert, RTRIM(pt.denumire) AS dentert,
			RTRIM(sc.marca) AS marca, sc.idPotential AS idPotential, RTRIM(pt.denumire) AS denPotential,
			'wmIaListaActivitatiCRM' AS procdetalii,
			(CASE WHEN sc.stare IN ('N', 'L') THEN (CASE WHEN sc.termen < GETDATE() THEN '0xFF0000' WHEN sc.termen = CONVERT(date, GETDATE()) 
				THEN '0xFFFF00' ELSE '0x007700' END) ELSE '0xA0A0A0' END) AS culoare
		FROM SarciniCRM sc
		LEFT JOIN personal p ON p.Marca = sc.marca
		LEFT JOIN Potentiali pt ON pt.idPotential = sc.idPotential
		OUTER APPLY (SELECT * FROM #activitati ac WHERE ac.idSarcina = sc.idSarcina) AS x
		WHERE (@lista_lm = 0 OR EXISTS (SELECT 1 FROM LMFiltrare l WHERE l.cod = p.Loc_de_munca))
			AND (@searchText IS NULL OR sc.descriere LIKE '%' + @searchText + '%' OR x.note IS NOT NULL)
			AND (@idPotential IS NULL OR sc.idPotential = @idPotential)
		ORDER BY sc.termen DESC, prioritate ASC
		FOR XML RAW, TYPE
	)

	SELECT @adaugare, @lista_sarcini
	FOR XML PATH('Date'), TYPE

	SELECT 1 AS _toateAtr, 1 AS areSearch, 'Sarcina' AS titlu
	FOR XML RAW, ROOT('Mesaje')

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
