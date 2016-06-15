
CREATE PROCEDURE wOPGenerareComenziProductie @sesiune VARCHAR(50), @parXML XML
AS
begin try
	IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'wOPGenerareComenziProductieSP'	AND type = 'P')
	BEGIN
		EXEC wOPGenerareComenziProductieSP @sesiune = @sesiune, @parXML = @parXML
		RETURN
	END

	DECLARE 
		@fltCod VARCHAR(20), @count INT, @c INT, @rand XML, @listaID XML, @child XML, @f XML, @idVechi INT, @idParinteVechi INT, 
		@idParinteNou INT, @idNou INT, @fltDenumire VARCHAR(80), @cantitateLansare FLOAT, @fltTip VARCHAR(20), @id INT, @idTehnologie INT, 
		@dataInchisa DATETIME, @utilizator VARCHAR(20), @parXML2 XML, @subunitate VARCHAR(20), @comanda VARCHAR(20), @nrCom INT, @fXML XML, 
		@countComenzi INT, @produse BIT, @cuPlanificare BIT, @tipLans BIT, @nivel INT, @maiSuntRanduri INT, @mesaj varchar(4000), @idParinteComandaTop int,
		@dinProcedura bit, @termen datetime, @tert varchar(20), @xml_jurnal xml

	/*
		Daca se apelaeaza cu "dinProcedura"=1 inseamna ca nu trebuie apelat la sfarsit wIaFundamentareLans - aceasta se apealeaza doar daca vine din macheta
	*/
	-- validare utilizator  
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	-- citire date din par  
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	EXEC luare_date_par 'MP', 'TIPLANS', 0, @tipLans OUTPUT, ''
	EXEC luare_date_par 'MP', 'CUPLANIF ', @cuPlanificare OUTPUT, 0, ''
	
	select	
		@idParinteComandaTop=@parXML.value('(/row/@idParinteTop)[1]', 'int'),
		@dinProcedura=ISNULL(@parXML.value('(/row/@dinProcedura)[1]', 'bit'),0),
		@tert=@parXML.value('(/row/@tert)[1]', 'varchar(20)'),
		@termen=@parXML.value('(/row/@termen)[1]', 'datetime')

	SELECT 
		@dataInchisa = CONVERT(DATETIME, Val_alfanumerica)
	FROM par
	WHERE Tip_parametru = 'MP'
		AND Parametru = 'DATAINCH'

	SELECT 
		@parXML2 = valoare
	FROM parSesiuniRIA
	WHERE username = @utilizator
		AND param = 'FLTFLANS'

	SELECT 
		@fltDenumire = '%' + REPLACE(isnull((@parXML2.value('(/row/@f_denumire)[1]', 'varchar(80)')), ''), ' ', '%') + '%', 
		@fltCod = '%' + REPLACE(isnull((@parXML2.value('(/row/@f_cod)[1]', 'varchar(80)')), '%'), ' ', '') + '%'

	--PENTRU PRODUSE  
	SELECT 
		@countComenzi = COUNT(1)
	FROM tmpprodsisemif t
	INNER JOIN tehnologii tt on tt.cod=t.codNomencl
	INNER JOIN nomencl n ON n.Cod = tt.codNomencl
		AND t.utilizator = @utilizator
	WHERE t.codNomencl LIKE @fltCod
		AND n.Denumire LIKE @fltDenumire

	IF @countComenzi > 0 --Sunt produse de lansat   
	BEGIN
		/** Plaja pentru comenzi de productie; iau mai multe numere, pentru ca lansez tot odata**/
		select @fxml= (select 'LS' meniu, 'LS' tip, @countComenzi documente, @utilizator utilizator for xml raw)
		
		EXEC wIauNrDocFiscale @parXML = @fXML, @Numar = @nrCom OUTPUT

		SET @nrCom = @nrCom - 1

		CREATE TABLE #comenziDeScris (comanda VARCHAR(20), tert VARCHAR(20), idPozContract int, cod VARCHAR(20), cantitate FLOAT, termen datetime, comanda_benef varchar(20))

		/** Tabelul de manevra #comenziDeScris **/
		INSERT INTO #comenziDeScris (comanda, tert, idPozContract, cod, cantitate, termen, comanda_benef)
		SELECT 
			convert(VARCHAR(20), @nrCom + ROW_NUMBER() OVER (ORDER BY t.codNomencl)) AS comanda, RTRIM(coalesce(@tert,c.tert,'')), 
			pc.idPozContract, rtrim(t.codNomencl), tmp.cantitate, coalesce(pc.termen, @termen ), c.numar
		FROM tmpprodsisemif tmp
		INNER JOIN tehnologii t on t.cod=tmp.codNomencl
		LEFT JOIN nomencl n ON n.Cod = t.codNomencl
		LEFT JOIN PozContracte pc on pc.idPozContract=tmp.idPozContract
		LEFT JOIN Contracte c on c.idContract=pc.idContract
		WHERE 
			tmp.codNomencl LIKE @fltCod
			AND n.denumire LIKE @fltDenumire
			AND tmp.utilizator = @utilizator

		/** Scriere in Comenzi **/
		INSERT INTO comenzi (
			Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, Starea_comenzii, Grup_de_comenzi, 
			Loc_de_munca, Numar_de_inventar, Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef)
		SELECT 
			'1', c.comanda, 'P', RTRIM(n.Denumire), GETDATE(), GETDATE(), 'P' AS starea_comenzii, '' AS grup_de_comenzi, '' AS 
			loc_de_munca, ISNULL(convert(varchar(10), c.termen,101),'') AS numar_de_inventar, isnull(C.tert, '') AS beneficiar, '' AS Loc_de_munca_beneficiar, ISNULL(c.comanda_benef,''), 
			'' AS Art_calc_benef
		FROM #comenziDeScris c
		INNER JOIN nomencl n ON n.Cod = c.cod

		/** Scriere in pozcom - pozitii comenzi**/
		CREATE TABLE #pozComIntroduse (comanda VARCHAR(20), cod VARCHAR(20), cantitate FLOAT)

		INSERT INTO pozcom (Subunitate, Comanda, Cod_produs, Cantitate, UM)
		SELECT '1', c.comanda, c.cod, c.cantitate, n.UM
		FROM #comenziDeScris c
		INNER JOIN nomencl n ON n.Cod = c.cod

		CREATE TABLE #iduri (comanda varchar(20), idPozLansare int)

		/** Scriere antet-uri in pozLansari **/
		INSERT INTO pozLansari (tip, cod, cantitate, idp, parinteTop)
		OUTPUT inserted.cod,inserted.id
		INTO #iduri(comanda,idPozLansare)
		SELECT 'L', c.comanda, c.cantitate, pt.id, @idParinteComandaTop
		FROM #comenziDeScris c
		INNER JOIN Tehnologii t on c.cod=t.codNomencl
		INNER JOIN pozTehnologii pt ON pt.tip = 'T' AND pt.idp IS NULL	AND t.cod = pt.cod

		set @xml_jurnal = (select idPozLansare idComanda, 'P' stare, GETDATE() data, 'Introducere/Generare comanda' explicatii from #iduri for xml raw, root('Date'), type)
		exec wScriuJurnalComenzi @Sesiune=@sesiune, @parXML=@xml_jurnal
		
		/**  "Copiere" tehnologie in pozLansare daca este tipul 0 TIPLANS in par **/
		IF @tipLans = 0
			--Cu structura, scriere toata tehnologia  
		BEGIN
			DECLARE crsLansari CURSOR
			FOR
			SELECT idPozLansare
			FROM #iduri

			OPEN crsLansari

			FETCH NEXT
			FROM crsLansari
			INTO @id

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @idTehnologie = idp, @cantitateLansare = cantitate
				FROM pozLansari
				WHERE id = @id;

				WITH arbore (id, tip, cod, resursa, cantitate, idp, parinteTop, idNou, ordine_o, cantitate_i, nivel)
				AS (
					SELECT id, tip, cod, resursa, @cantitateLansare, idp, parinteTop, @id, ordine_o, cantitate_i, 0
					FROM poztehnologii
					WHERE id = @idTehnologie
				
					UNION ALL
				
					SELECT pTehn.id, pTehn.tip, pTehn.cod, pTehn.resursa, pTehn.cantitate * arb.cantitate, pTehn.idp, pTehn.
						parinteTop, 0, pTehn.ordine_o, pTehn.cantitate_i, arb.nivel + 1
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
					INSERT INTO pozLansari (tip, cod, resursa, cantitate, idp, ordine_o, cantitate_i, parinteTop)
					OUTPUT inserted.ID, inserted.cod, inserted.tip
					INTO #idNoi(id, cod, tip)
					SELECT tp.tip, tp.cod, tp.resursa, tp.cantitate, tp2.idNou, tp.ordine_o, tp.cantitate_i, @id
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
		INSERT INTO dependenteLans (idPozContract,idPozLansare)
		SELECT cds.idPozContract,d.idPozLansare
		FROM #iduri d
		JOIN #comenziDeScris cds on cds.comanda=d.comanda where cds.idPozContract is not null

	END


	if @dinProcedura<>1
	begin
		DECLARE @doc XML
		SET @doc = (SELECT 0 AS _refresh FOR XML raw)
		EXEC wIaFundamentareLans @sesiune = @sesiune, @parXML = @doc
	end
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wOPGenerareComenziProductie)'
	raiserror(@mesaj, 15, 1)
end catch
