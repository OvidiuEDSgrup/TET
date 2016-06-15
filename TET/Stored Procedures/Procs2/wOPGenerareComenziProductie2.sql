
CREATE PROCEDURE [dbo].[wOPGenerareComenziProductie2] @sesiune VARCHAR(50), @parXML XML
AS
begin try
	DECLARE @fltCod VARCHAR(20), @count INT, @c INT, @rand XML, @listaID XML, @child XML, @f XML, @idVechi INT, @idParinteVechi INT, 
		@idParinteNou INT, @idNou INT, @fltDenumire VARCHAR(80), @cantitateLansare FLOAT, @fltTip VARCHAR(20), @id INT, @idTehnologie INT
		, @dataInchisa DATETIME, @utilizator VARCHAR(20), @parXML2 XML, @subunitate VARCHAR(20), @comanda VARCHAR(20), @nrCom INT, @fXML 
		XML, @countComenzi INT, @produse BIT, @cuPlanificare BIT, @tipLans BIT, @nivel INT, @maiSuntRanduri INT, @mesaj varchar(max)

	-- validare utilizator  
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	-- citire date din par  
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	EXEC luare_date_par 'MP', 'TIPLANS', 0, @tipLans OUTPUT, ''

	EXEC luare_date_par 'MP', 'CUPLANIF ', @cuPlanificare OUTPUT, 0, ''

	SELECT @dataInchisa = CONVERT(DATETIME, Val_alfanumerica)
	FROM par
	WHERE Tip_parametru = 'MP'
		AND Parametru = 'DATAINCH'

	SELECT @parXML2 = valoare
	FROM parSesiuniRIA
	WHERE username = @utilizator
		AND param = 'FLTFLANS'

	SELECT @fltDenumire = '%' + REPLACE(isnull((@parXML2.value('(/row/@f_denumire)[1]', 'varchar(80)')), ''), ' ', 
			'%') + '%', @fltCod = '%' + REPLACE(isnull((@parXML2.value('(/row/@f_cod)[1]', 'varchar(80)')), '%'), ' ', 
			'') + '%'

	--PENTRU PRODUSE  
	SELECT @countComenzi = COUNT(1)
	FROM tmpprodsisemif t
	INNER JOIN nomencl n ON n.Cod = t.codNomencl
		AND t.utilizator = @utilizator
	WHERE t.codNomencl LIKE @fltCod
		AND n.Denumire LIKE @fltDenumire

	IF @countComenzi > 0 --Sunt produse de lansat   
	BEGIN
		/** Plaja pentru comenzi de productie; iau mai multe numere, pentru ca lansez tot odata**/
		SET @fXML = '<row tip="UK"/>'
		SET @fXML.modify('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		SET @fXML.modify('insert attribute documente {sql:variable("@countComenzi")} into (/row)[1]')

		EXEC wIauNrDocFiscale @parXML = @fXML, @Numar = @nrCom OUTPUT

		SET @nrCom = @nrCom - 1

		CREATE TABLE #comenziDeScris (comanda VARCHAR(20), tert VARCHAR(20), contract VARCHAR(20), cod VARCHAR(20), cantitate FLOAT
			)

		/** Tabelul de manevra #comenziDeScris **/
		INSERT INTO #comenziDeScris (comanda, tert, contract, cod, cantitate)
		SELECT 'L' + convert(VARCHAR(19), @nrCom + ROW_NUMBER() OVER (
					ORDER BY tmp.codNomencl
					)) AS comanda, RTRIM(c.tert), RTRIM(c.Contract), rtrim(tmp.codNomencl), tmp.cantitate
		FROM tmpprodsisemif tmp
		LEFT JOIN nomencl n ON n.Cod = tmp.codNomencl
		LEFT JOIN con c ON c.Subunitate = @subunitate
			AND c.Tip = 'BK'
			AND c.Data > @dataInchisa
			AND c.Stare = 1
			AND c.Contract = tmp.codp
		LEFT JOIN pozcon pc ON tmp.codNomencl = pc.Cod
			AND pc.Subunitate = c.Subunitate
			AND pc.Tip = c.Tip
			AND pc.Contract = c.Contract
			AND pc.Tert = c.Tert
			AND pc.Data = c.Data
		WHERE tmp.codNomencl LIKE @fltCod
			AND n.denumire LIKE @fltDenumire
			AND tmp.utilizator = @utilizator

		/** Scriere in Comenzi **/
		INSERT INTO comenzi (
			Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, Starea_comenzii, Grup_de_comenzi, 
			Loc_de_munca, Numar_de_inventar, Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef
			)
		SELECT '1', c.comanda, 'P', RTRIM(n.Denumire), GETDATE(), GETDATE(), 'L' AS starea_comenzii, '' AS grup_de_comenzi, '' AS 
			loc_de_munca, '' AS numar_de_inventar, isnull(C.tert, '') AS beneficiar, '' AS Loc_de_munca_beneficiar, isnull(c.Contract, 
				'') AS Comanda_beneficiar, '' AS Art_calc_benef
		FROM #comenziDeScris c
		INNER JOIN nomencl n ON n.Cod = c.cod

		/** Scriere in pozcom - pozitii comenzi**/
		CREATE TABLE #pozComIntroduse (comanda VARCHAR(20), cod VARCHAR(20), cantitate FLOAT)

		INSERT INTO pozcom (Subunitate, Comanda, Cod_produs, Cantitate, UM)
		SELECT '1', c.comanda, c.cod, c.cantitate, n.UM
		FROM #comenziDeScris c
		INNER JOIN nomencl n ON n.Cod = c.cod

		CREATE TABLE #id (id INT)

		/** Scriere antet-uri in pozLansari **/
		INSERT INTO pozLansari (tip, cod, cantitate, idp)
		OUTPUT inserted.id
		INTO #id
		SELECT 'L', c.comanda, c.cantitate, t.id
		FROM #comenziDeScris c
		INNER JOIN pozTehnologii t ON t.tip = 'T'
			AND t.idp IS NULL
			AND t.cod = c.cod

		/**  "Copiere" tehnologie in pozLansare daca este tipul 0 TIPLANS in par **/
		IF @tipLans = 0
			--Cu structura, scriere toata tehnologia  
		BEGIN
			DECLARE crsLansari CURSOR
			FOR
			SELECT id
			FROM #id

			OPEN crsLansari

			FETCH NEXT
			FROM crsLansari
			INTO @id

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @idTehnologie = idp, @cantitateLansare = cantitate
				FROM pozLansari
				WHERE id = @id;

				WITH arbore (id, tip, cod, resursa, cantitate, idp, parinteTop, idNou, nivel)
				AS (
					SELECT id, tip, cod, resursa, @cantitateLansare, idp, parinteTop, @id, 0
					FROM poztehnologii
					WHERE id = @idTehnologie
				
					UNION ALL
				
					SELECT pTehn.id, pTehn.tip, pTehn.cod, pTehn.resursa, pTehn.cantitate * arb.cantitate, pTehn.idp, pTehn.
						parinteTop, 0, arb.nivel + 1
					FROM pozTehnologii pTehn
					INNER JOIN arbore arb ON pTehn.tip IN ('M', 'O')
						AND arb.id = pTehn.idp
					)
				SELECT *
				INTO #tmpTehnologie
				FROM arbore

				SET @nivel = 1
				SET @maiSuntRanduri = 1

				CREATE TABLE #idNoi (id INT, cod VARCHAR(20), tip VARCHAR(20))

				WHILE @maiSuntRanduri > 0
				BEGIN
					INSERT INTO pozLansari (tip, cod, resursa, cantitate, idp, parinteTop)
					OUTPUT inserted.ID, inserted.cod, inserted.tip
					INTO #idNoi(id, cod, tip)
					SELECT tp.tip, tp.cod, tp.resursa, tp.cantitate, tp2.idNou, @id
					FROM #tmpTehnologie tp
					LEFT JOIN #tmpTehnologie tp2 ON tp.idp = tp2.id
					WHERE tp.nivel = @nivel

					SET @maiSuntRanduri = @@ROWCOUNT

					UPDATE #tmpTehnologie
					SET idNou = #idNoi.id
					FROM #idNoi
					WHERE #idNoi.tip = #tmpTehnologie.tip
						AND #idNoi.cod = #tmpTehnologie.cod
						AND #tmpTehnologie.nivel = @nivel

					SELECT @nivel = @nivel + 1
				END

				DROP TABLE #idNoi

				DROP TABLE #tmpTehnologie

				--Gata copiere tehnologie
				FETCH NEXT
				FROM crsLansari
				INTO @id
			END

			CLOSE crsLansari

			DEALLOCATE crsLansari
		END

		/** Tratare planificari daca este CUPLANIF = 1 in par **/
		IF @cuPlanificare = 1
		BEGIN
			exec wOPPlanificaComenziProductie @sesiune=@sesiune, @parXML=@parXML
		END

		/** Scriere dependenteLans- asociere comenzi de productie la contracte **/
		INSERT INTO dependenteLans (comanda, cod, tert, contract, comandaleg)
		SELECT contract, cod, tert, contract, comanda
		FROM #comenziDeScris
		WHERE contract IS NOT NULL
			AND tert IS NOT NULL
	END

	DECLARE @doc XML

	SET @doc = (
			SELECT 0 AS _refresh
			FOR XML raw
			)

	EXEC wIaFundamentareLans @sesiune = @sesiune, @parXML = @doc
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wOPGenerareComenziProductie2)'
	raiserror(@mesaj, 11, 1)
end catch