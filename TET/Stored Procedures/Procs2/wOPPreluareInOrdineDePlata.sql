
CREATE PROCEDURE wOPPreluareInOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idOP INT, @sursa VARCHAR(1), @docPozitii XML, @data DATETIME, @cont VARCHAR(20), @conturiFiltru VARCHAR(max), @facturi 
		VARCHAR(max), @tertCurent VARCHAR(100), @sold FLOAT, @mesaj VARCHAR(500)

	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')
	SET @sursa = @parXML.value('(/*/@sursa)[1]', 'varchar(1)')
	SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')

	IF OBJECT_ID('tempdb..#pozitiiPreluare') IS NOT NULL
		DROP TABLE #pozitiiPreluare

	CREATE TABLE #pozitiiPreluare (tert VARCHAR(20), factde VARCHAR(20), sold FLOAT, facturi VARCHAR(max), total FLOAT)

	IF @sursa = 'D'
		/** Populare din deconturi **/
	BEGIN
		EXEC luare_date_par 'OP', 'CDECONTURI', 0, 0, @conturiFiltru OUTPUT

		IF isnull(@conturiFiltru, '') = ''
			SET @conturiFiltru = '542'

		INSERT INTO #pozitiiPreluare (tert, factde, sold)
		SELECT RTRIM(d.Marca) tert, RTRIM(d.decont) factde, sold
		FROM deconturi d
		INNER JOIN fSplit(@conturiFiltru, ',') fc
			ON d.Cont LIKE fc.string + '%'
		WHERE d.Data <= @data
			AND sold > 0.0001
		ORDER BY d.Marca
	END
	ELSE
		IF @sursa = 'F'
			/** Populare din facturi  */
		BEGIN
			EXEC luare_date_par 'OP', 'CFACTURI', 0, 0, @conturiFiltru OUTPUT

			IF isnull(@conturiFiltru, '') = ''
				SET @conturiFiltru = '401,404'

			INSERT INTO #pozitiiPreluare (tert, factde, sold)
			SELECT rtrim(tert) tert, rtrim(Factura) factde, sold
			FROM facturi f
			INNER JOIN fSplit(@conturiFiltru, ',') fc
				ON f.Cont_de_tert LIKE fc.string + '%'
			WHERE f.tip = 0x54
				AND Data_scadentei <= @data
				AND sold > 0.0001
			ORDER BY f.Tert
		END

	SET @tertCurent = ''
	SET @facturi = ''
	SET @sold = 0

	UPDATE p
	SET @facturi = (CASE WHEN @tertCurent <> tert THEN '' ELSE @facturi END) + ',' + rtrim(factde), @sold = (CASE WHEN @tertCurent <> tert THEN 0 ELSE @sold END
			) + sold, facturi = @facturi, total = @sold, @tertCurent = tert
	FROM #pozitiiPreluare p

	IF OBJECT_ID('tempdb..#pozitiiPreluareCen') IS NOT NULL
		DROP TABLE #pozitiiPreluareCen

	SELECT poz.tert, REPLACE(LTRIM(RTRIM(REPLACE(poz.facturi, ',', ' '))), ' ', ',') listaFacturi, poz.total sold
	INTO #pozitiiPreluareCen
	FROM #pozitiiPreluare poz
	INNER JOIN (
		SELECT tert, MAX(total) total
		FROM #pozitiiPreluare
		GROUP BY tert
		) linieMax
		ON poz.tert = linieMax.tert
			AND poz.total = linieMax.total

	SET @docPozitii = (
			SELECT @idOP idOP, @sursa sursa, '1' AS preluare, @data data, @cont cont, (
					SELECT @sursa AS tipPoz, (CASE @sursa WHEN 'F' THEN rtrim(t.Cont_in_banca) WHEN 'D' THEN rtrim(p.Cont_in_banca) END
							) AS iban, (CASE @sursa WHEN 'D' THEN rtrim(p.Banca) WHEN 'F' THEN rtrim(t.Banca) END
							) AS banca, convert(DECIMAL(18, 5), pp.sold) suma, 'I' stare, (
							SELECT rtrim(pp.tert) tert, (
									SELECT p.factde document, convert(DECIMAL(18, 5), p.sold) sold
									FROM #pozitiiPreluare p
									WHERE p.tert = pp.tert
									FOR XML raw, type
									)
							FOR XML raw, type
							) documente, (
							CASE @sursa WHEN 'F' THEN isnull(rtrim(t.Denumire), '') + ' Plata facturi: ' WHEN 'D' THEN 
										'Plata deconturi: ' END
							) + pp.listaFacturi AS explicatii
					FROM #pozitiiPreluareCen pp
					LEFT JOIN terti t
						ON t.Tert = pp.tert
					LEFT JOIN personal p
						ON p.Marca = pp.tert
					FOR XML raw, type
					)
			FOR XML raw, type
			)

	EXEC wScriuPozOrdineDePlata @sesiune = @sesiune, @parXML = @docPozitii
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPreluareInOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
