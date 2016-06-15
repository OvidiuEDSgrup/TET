
--***
CREATE PROCEDURE wScriuTE @parXmlScriereIesiri XML
OUTPUT AS

BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuTESP')
		exec wScriuTESP @parXmlScriereIesiri output

	DECLARE @tip varchar(2), @Numar VARCHAR(20), @Data DATETIME, @GestPred CHAR(9), @GestPrim CHAR(9), @GestDest CHAR(20), 
		@Cod CHAR(20), @CodIntrare CHAR(13), @CodIPrim CHAR(13), @Cantitate FLOAT, @LocatiePrim CHAR(30), @PretAmPrim FLOAT, @CategPret INT, @Valuta CHAR(3), 
		@Curs FLOAT, @LM CHAR(9), @Comanda CHAR(40), @ComLivr CHAR(20), @Jurnal CHAR(3), @Stare INT, @Barcod CHAR(30), @Schimb INT, 
		@Serie CHAR(20), @Utilizator CHAR(10), @PastrCtSt INT, @Valoare FLOAT, @TotCant FLOAT, @NrPozitie INT, @CtCoresp VARCHAR(40), 
		@CtIntermediar VARCHAR(40), @TVAnx FLOAT, @update BIT, @subtip VARCHAR(2), @mesaj VARCHAR(200), @iDoc INT, @docInserate XML,
		@docDetalii XML, @detalii xml, @idIntrare int, @idIntrareFirma int

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri

	SELECT @tip = tip, @Numar = isnull(numar, ''), @Data = data, @GestPred = gestiune, @GestPrim = gestiune_primitoare, @GestDest = contract, @Cod = 
		cod, @CodIntrare = cod_intrare, @CodIPrim = (CASE WHEN codiPrim = '' THEN NULL ELSE codiPrim END), @Cantitate = 
		cantitate, @LocatiePrim = ISNULL(NULLIF(locatieprim,''),locatie), @PretAmPrim = pret_amanunt, @CategPret = ISNULL(categ_pret, ''), @Valuta = valuta, @Curs = 
		curs, @LM = lm, @Comanda = isnull(comanda_bugetari,comanda), @ComLivr = factura, @Jurnal = jurnal, @Stare = stare, @Barcod = barcod, @Schimb = 0, 
		@Serie = isnull(serie, 0), @Utilizator = ISNULL(utilizator, ''), @PastrCtSt = 0, @Valoare = NULL, @TotCant = NULL, @NrPozitie = 
		ISNULL(numar_pozitie, 0), @CtCoresp = cont_corespondent, @CtIntermediar = isnull(contintermediar, ''), @TVAnx = TVAnx, 
		@update = isnull(ptupdate, 0), @subtip = isnull(subtip,''), @detalii=detalii
	FROM OPENXML(@iDoc, '/row') WITH (
			tip CHAR(2) '@tip', subtip CHAR(2) '@subtip', numar VARCHAR(20) '@numar', data DATETIME '@data', tert CHAR(13) '@tert', 
			factura CHAR(20) '@factura', data_facturii DATETIME '@data_facturii', data_scadentei DATETIME '@data_scadentei', 
			cont_factura CHAR(13) '@cont_factura', gestiune CHAR(9) '@gestiune', cod CHAR(20) '@cod', cod_intrare CHAR(20) '@cod_intrare', 
			codiPrim CHAR(20) '@codiPrim', cantitate FLOAT '@cantitate', valuta VARCHAR(3) '@valuta', curs VARCHAR(14) '@curs', 
			pret_valuta FLOAT '@pret_valuta', discount FLOAT '@discount', pret_amanunt FLOAT '@pret_amanunt', lm CHAR(9) '@lm', 
			comanda_bugetari CHAR(40) '@comanda_bugetari', comanda CHAR	(20) '@comanda', contract CHAR(20) '@contract', jurnal CHAR(3) '@jurnal', 
			stare INT '@stare', barcod CHAR(30) '@barcod', tipTVA INT '@tipTVA', utilizator CHAR(20) '@utilizator', serie CHAR(20) '@serie', 
			suma_tva FLOAT '@suma_tva', cota_TVA FLOAT '@cota_TVA', locatie CHAR(30) '@locatie', locatieprim char(30) '@locatieprim',
			 numar_pozitie INT '@numar_pozitie', suprataxe FLOAT 
			'@suprataxe', cont_corespondent VARCHAR(40) '@cont_corespondent', contintermediar VARCHAR(40) '@contintermediar', 
			ptupdate INT '@update', explicatii VARCHAR(30) '@explicatii', punct_livrare VARCHAR(30) '@punct_livrare', categ_pret 
			VARCHAR(30) '@categ_pret', gestiune_primitoare VARCHAR(30) '@gestiune_primitoare', TVAnx FLOAT '@TVAnx',
			detalii xml 'detalii'
			)

	--SET @Comanda = @parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)')

	--din cursor nu stie sa citeasca cu spatiile din fata!!	
	IF isnull(@utilizator, '') = ''
	BEGIN
		RAISERROR ('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!', 11, 1
				)

		RETURN - 1
	END

	DECLARE @Sb CHAR(9), @TabPreturi INT, @TLitR INT, @Accize INT, @CtAccCR VARCHAR(40), @FaraTVAnx INT, @Ct348 VARCHAR(40), @DifPProd INT, 
		@CtIntTE VARCHAR(40), @Ct378 VARCHAR(40), @AnGest378 INT, @AnGr378 INT, @Ct4428 VARCHAR(40), @AnGest4428 INT, @TipNom CHAR(1), 
		@CtNom VARCHAR(40), @PStocNom FLOAT, @PAmNom FLOAT, @GrNom CHAR(13), @CoefConv2Nom FLOAT, @CategNom INT, @GreutSpecNom FLOAT, @TVANom 
		FLOAT, @TipGestPred CHAR(1), @TipGestPrim CHAR(1), @CtGestPrim VARCHAR(40), @PretSt FLOAT, @CtStoc VARCHAR(40), @PretAmPred FLOAT, 
		@LocatieStoc CHAR(30), @DataExpStoc DATETIME, @DinCust INT, @PVanzSt FLOAT, @PAmPreturi FLOAT, @PVanzPreturi FLOAT, 
		@PretVanz FLOAT, @CtInterm VARCHAR(40), @CtAdPred VARCHAR(40), @CtAdPrim VARCHAR(40), @CtTVAnxPred VARCHAR(40), @CtTVAnxPrim VARCHAR(40), 
		@AccCump FLOAT, @AccDat FLOAT, @StersPozitie INT, @Serii INT, @AcCodIPrimitor INT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb OUTPUT

	EXEC luare_date_par 'GE', 'PRETURI', @TabPreturi OUTPUT, 0, ''

	EXEC luare_date_par 'GE', 'TIMBRULT2', @TLitR OUTPUT, 0, ''

	EXEC luare_date_par 'GE', 'ACCIZE', @Accize OUTPUT, 0, ''

	EXEC luare_date_par 'GE', 'CACCIZE', 0, 0, @CtAccCR OUTPUT

	EXEC luare_date_par 'GE', 'CADAOS', @AnGest378 OUTPUT, @AnGr378 OUTPUT, @Ct378 OUTPUT

	EXEC luare_date_par 'GE', 'CNTVA', @AnGest4428 OUTPUT, 0, @Ct4428 OUTPUT

	EXEC luare_date_par 'GE', 'FARATVANE', @FaraTVAnx OUTPUT, 0, ''

	EXEC luare_date_par 'GE', 'CONT348', @DifPProd OUTPUT, 0, @Ct348 OUTPUT

	EXEC luare_date_par 'GE', 'CALTE', 0, 0, @CtIntTE OUTPUT

	EXEC luare_date_par 'GE', 'SERII', @Serii OUTPUT, 0, ''

	EXEC luare_date_par 'UC', 'TEACCODI', @AcCodIPrimitor OUTPUT, 0, ''

	--EXEC luare_date_par 'SP', 'ORTO', @Ortoprofil OUTPUT, 0, ''

	EXEC iauNrDataDoc 'TE', @Numar OUTPUT, @Data OUTPUT, 0

	IF isnull(@Stare, 0) = 0
		SET @Stare = 3
	SET @TipNom = ''
	SET @CtNom = ''
	SET @PStocNom = 0
	SET @PAmNom = 0
	SET @GrNom = ''
	SET @CoefConv2Nom = 0
	SET @CategNom = 0
	SET @GreutSpecNom = 0
	SET @TVANom = 0

	SELECT @TipNom = tip, @CtNom = cont, @PStocNom = pret_stoc, @PAmNom = pret_cu_amanuntul, @GrNom = grupa, @CoefConv2Nom = 
		Coeficient_conversie_1, @CategNom = categorie, @GreutSpecNom = greutate_specifica, @TVANom = Cota_TVA
	FROM nomencl
	WHERE cod = @Cod

	SET @TipGestPred = ''

	SELECT @TipGestPred = tip_gestiune
	FROM gestiuni
	WHERE subunitate = @Sb
		AND cod_gestiune = @GestPred

	SET @TipGestPrim = ''
	SET @CtGestPrim = ''

	SELECT @TipGestPrim = tip_gestiune, @CtGestPrim = cont_contabil_specific
	FROM gestiuni
	WHERE subunitate = @Sb
		AND cod_gestiune = @GestPrim

	SELECT @PretSt = pret, @CtStoc = cont, @TVAnx = (CASE WHEN tip_gestiune = 'A' THEN tva_neexigibil ELSE @TVAnx END), 
		@PretAmPred = pret_cu_amanuntul, @LocatieStoc = locatie, @DataExpStoc = data_expirarii, @DinCust = 
		are_documente_in_perioada, @PVanzSt = pret_vanzare, @idIntrare=idIntrare, @idIntrareFirma=idIntrareFirma
	FROM stocuri
	WHERE @TipGestPred <> 'V'
		AND subunitate = @Sb
		AND cod = @Cod
		-- la TE cu cant<0 citim datele din date stoc din gestiunea primitoare, daca e ales cod intrare primitor
		AND tip_gestiune = case when LEN(@codiPrim)>0 and @cantitate<-0.001 then @TipGestPrim  else @TipGestPred end 
		AND cod_gestiune = case when LEN(@codiPrim)>0 and @cantitate<-0.001 then @GestPrim else @GestPred end 
		AND cod_intrare =  case when LEN(@codiPrim)>0 and @cantitate<-0.001 then @codiPrim else @CodIntrare end

	IF @PretSt IS NULL
		SET @PretSt = isnull(@PStocNom, 0)

	IF @CtStoc IS NULL
		SET @CtStoc = dbo.formezContStoc(isnull(@GestPred, ''), isnull(@Cod, ''), isnull(@LM, ''))

	IF @DinCust IS NULL
		SET @DinCust = 0

	
	--Luare preturi din tabela de preturi
	declare @preturiXML xml
	create table #preturi(cod varchar(20),nestlevel int)
	insert into #preturi
	select @Cod,@@NESTLEVEL

	set @preturiXML='<row categoriePret="'+ rtrim(@categpret) +'" />'
	
	exec CreazaDiezPreturi
	exec wIaPreturi @sesiune='',@parXML=@preturiXML
		
	select @PAmPreturi=pret_amanunt, @PVanzPreturi=pret_vanzare from #preturi where cod=@cod

	IF isnull(@TVAnx, 0) = 0
		AND @TipGestPrim  in ('A','V')
		SET @TVAnx = @TVANom

	IF /*@TVAnx is null and */ @TipGestPrim = 'A'
		AND left(@CtGestPrim, 2) = '35'
		AND @DifPProd = 1
		AND left(@CtStoc, 2) IN ('33', '34')
		OR @FaraTVAnx = 1
		SET @TVAnx = 0

	IF @TipGestPred <> 'A'
		AND @DifPProd = 1
		AND left(@CtStoc, 2) IN ('33', '34')
		SET @PretAmPred = (
				CASE WHEN @TipGestPrim = 'A'
						AND left(@CtGestPrim, 3) = '371' THEN (CASE WHEN @DinCust = 1 THEN @PVanzSt ELSE @PVanzPreturi END
								) ELSE 0 /*??? aici ar trebui pret amanunt primitor...*/ END
				)

	IF @PretAmPred IS NULL
		SET @PretAmPred = 0

	IF isnull(@PretAmPrim, 0) = 0
	BEGIN
		IF @TipGestPrim IN ('A', 'C')
			OR @TipGestPrim = 'V'
			AND @TipGestPred <> 'A'
			SET @PretAmPrim = isnull(@PAmPreturi, @PAmNom)

		IF @PretAmPrim IS NULL
			AND @TipGestPrim = 'V'
			AND @TipGestPred = 'A'
			SET @PretAmPrim = @PretAmPred

		IF @PretAmPrim IS NULL
			SET @PretAmPrim = @PAmNom
	END

	IF isnull(@CtCoresp, '') = ''
		AND left(@CtStoc, 1) = '8'
		SET @CtCoresp = @CtStoc

	/*IF @Ortoprofil=1 AND isnull(@CtCoresp, '') = '' AND left(@CtGestPrim, 3) = '357' AND @TipNom = 'P'
		SET @CtCoresp = '354'*/

	IF isnull(@CodIPrim, '') = ''
		-- mai jos, unde a fost trimis parametrul @Data am pus '1901-01-01' (in 2 locuri), pentru a verifica intreg stocul la primitor, nu doar cel cu data egala cu data documentului
		SET @CodIPrim = dbo.cautareCodIntrare(isnull(@Cod, ''), isnull(@GestPrim, ''), @TipGestPrim, isnull(@CodIntrare, ''), 
				@PretSt, @PretAmPrim, isnull(@CtCoresp, ''), @AcCodIPrimitor, 0, '1901-01-01', '1901-01-01', 
				'', '', @Comanda, @ComLivr, '', '')

	SELECT @CtCoresp = (
			CASE WHEN isnull(@CtCoresp, '') = '' THEN (CASE WHEN cont IN ('0', '371.') THEN '' ELSE cont END
							) ELSE @CtCoresp END
			), @PretAmPrim = (CASE WHEN isnull(@PretAmPrim, 0) = 0 THEN pret_cu_amanuntul ELSE @PretAmPrim END), 
		@LocatiePrim = (CASE WHEN isnull(@LocatiePrim, '') = '' THEN locatie ELSE @LocatiePrim END), @DataExpStoc = 
		data_expirarii
	FROM stocuri
	WHERE @TipGestPrim <> 'V'
		AND subunitate = @Sb
		AND tip_gestiune = @TipGestPrim
		AND cod_gestiune = @GestPrim
		AND cod = @Cod
		AND cod_intrare = @CodIPrim
		and abs(stoc)>=0.001

	SET @PretVanz = convert(DECIMAL(17, 5), @PretAmPrim / (1.00 + isnull(@TVAnx, 0) / 100))

	IF isnull(@LocatiePrim, '') = ''
		SET @LocatiePrim = isnull(@LocatieStoc, '')

	IF @DataExpStoc IS NULL
		SET @DataExpStoc = @Data

	IF isnull(@CtCoresp, '') = ''
		AND @PastrCtSt = 1
		AND @CtGestPrim = ''
		SET @CtCoresp = @CtStoc

	IF isnull(@CtCoresp, '') = ''
		SET @CtCoresp = dbo.formezContStoc(isnull(@GestPrim, ''), isnull(@Cod, ''), isnull(@LM, ''))

	IF @Accize = 1
		AND @TipGestPred = 'P'
	BEGIN
		DECLARE @AccCategProd INT, @AccUnitVanz FLOAT

		EXEC luare_date_par 'GE', 'CATEGPRO', @AccCategProd OUTPUT, 0, ''

		IF @AccCategProd = 1
		BEGIN
			SET @AccUnitVanz = isnull((
						SELECT max(acciza_vanzare)
						FROM categprod
						WHERE categoria = @CategNom
						), 0)
			SET @AccDat = round(convert(DECIMAL(17, 4), @CoefConv2Nom * @AccUnitVanz * isnull(@Cantitate, 0)), 3)
		END
	END

	IF @AccDat IS NULL
		SET @AccDat = 0
	SET @Valoare = isnull(@Valoare, 0) + round(convert(DECIMAL(17, 3), isnull(@Cantitate, 0) * @PretSt), 2)
	SET @TotCant = isnull(@TotCant, 0) + isnull(@Cantitate, 0)
	SET @CtInterm = (CASE WHEN @TipGestPred = 'V' THEN @CtIntTE WHEN @TLitR = 1 THEN @CtAccCR ELSE @CtIntermediar END)

	IF @DifPProd = 1
		AND left(isnull(@CtCoresp, ''), 1) <> '6'
		AND left(@CtStoc, 2) IN ('33', '34')
		SET @CtAdPred = @Ct348

	IF @CtAdPred IS NULL
		SET @CtAdPred = RTrim(@Ct378) + (CASE WHEN @AnGest378 = 1 THEN '.' + RTrim(isnull(@GestPred, '')) ELSE '' END) + (CASE WHEN @AnGr378 = 1 THEN '.' + RTrim(@GrNom) ELSE '' END
				)
	SET @CtTVAnxPred = RTrim(@Ct4428) + (CASE WHEN @AnGest4428 = 1 THEN '.' + RTrim(isnull(@GestPred, '')) ELSE '' END)
	SET @CtAdPrim = RTrim(@Ct378) + (CASE WHEN @AnGest378 = 1 THEN '.' + RTrim(isnull(@GestPrim, '')) ELSE '' END) + (CASE WHEN @AnGr378 = 1 THEN '.' + RTrim(@GrNom) ELSE '' END
			)
	SET @CtTVAnxPrim = RTrim(@Ct4428) + (CASE WHEN @AnGest4428 = 1 THEN '.' + RTrim(isnull(@GestPrim, '')) ELSE '' END)
	SET @AccCump = (CASE WHEN @TLitR = 1 THEN @GreutSpecNom WHEN @TabPreturi = 1 THEN @CategPret ELSE 0 END)

	IF isnull(@Utilizator, '') = ''
		SET @Utilizator = dbo.fIaUtilizator(NULL)

	--select @utilizator
	---start adaugare pozitie noua in pozdoc-----
	IF @update = 0
		AND @subtip <> 'SE'
	BEGIN
		EXEC luare_date_par 'DO', 'POZITIE', 0, @NrPozitie OUTPUT, '' --alocare numar pozitie

		SET @NrPozitie = @NrPozitie + 1

		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		IF isnull((
					SELECT max(left(UM_2, 1))
					FROM nomencl
					WHERE cod = @Cod
					), '') = 'Y'
			AND isnull(@Serie, '') <> ''
			AND @Serii <> 0
		BEGIN --daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			SELECT @cod = (CASE WHEN @Cod IS NULL THEN '' ELSE @cod END), @GestPred = (CASE WHEN @GestPred IS NULL THEN '' ELSE @GestPred END
					), @Cantitate = (CASE WHEN @Cantitate IS NULL THEN 0 ELSE @Cantitate END), @CodIntrare = (CASE WHEN @CodIntrare IS NULL THEN '' ELSE @CodIntrare END
					), @GestPrim = (CASE WHEN @GestPrim IS NULL THEN '' ELSE @GestPrim END)

			EXEC wScriuPDserii 'TE', @Numar, @Data, @GestPred, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, @GestPrim

			SET @Cantitate = isnull((
						SELECT SUM(cantitate)
						FROM pdserii
						WHERE tip = 'TE'
							AND Numar = @Numar
							AND data = @Data
							AND Gestiune = @GestPred
							AND cod = @Cod
							AND Gestiune_primitoare = @GestPrim
							AND Cod_intrare = isnull(@CodIntrare, '')
							AND Numar_pozitie = @NrPozitie
						), 0) --calcul cantitate pt pozdoc din pdserii
		END

		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------
		IF OBJECT_ID('tempdb..#TEInserat') IS NOT NULL
			DROP TABLE #TEInserat

		CREATE TABLE #TEInserat (idPozDoc INT)

		INSERT pozdoc (
			Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, 
			Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, Cod_intrare, Cont_de_stoc, 
			Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
			Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, 
			Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
			Accize_cumparare, Accize_datorate, Contract, Jurnal,subtip, idIntrare, idIntrareFirma
			)
		OUTPUT inserted.idPozDoc
		INTO #TEInserat(idPozDoc)
		VALUES (
			@Sb, 'TE', @Numar, isnull(@Cod, ''), @Data, isnull(@GestPred, ''), isnull(@Cantitate, 0), 0, @PretSt, 0, @PretVanz, 
			@PretAmPrim, 0, 0, isnull(@Utilizator, ''), convert(DATETIME, convert(CHAR(10), getdate(), 104), 104), RTrim(replace(
					convert(CHAR(8), getdate(), 108), ':', '')), isnull(@CodIntrare, ''), @CtStoc, isnull(@CtCoresp, ''), isnull(
				@TVAnx, 0), @PretAmPred, 'E', @LocatiePrim, @DataExpStoc, @NrPozitie, isnull(@LM, ''), isnull(@Comanda, ''), isnull
			(@Barcod, ''), @CtInterm, @CtAdPrim, @DinCust, @CtAdPred, isnull(@ComLivr, ''), isnull(@GestPrim, ''), @CtTVAnxPred, 
			@Stare, @CodIPrim, @CtTVAnxPrim, isnull(@Valuta, ''), isnull(@Curs, 0), @Data, @Data, @Schimb, 0, @AccCump, @AccDat, 
			isnull(@GestDest, ''), isnull(@Jurnal, ''),(case when @subtip=@tip then null else @subtip end), @idIntrare, @idIntrareFirma
			)

		SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #TEInserat
				FOR XML raw, root('Inserate')
				)
		
		SET @docDetalii = (
			SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, convert(char(10),@Data,101) data, 'TE' tip, 'pozdoc' as tabel, @detalii
			for xml raw
			)
		exec wScriuDetalii @parXML=@docDetalii

		EXEC setare_par 'DO', 'POZITIE', NULL, NULL, @NrPozitie, NULL
			--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
	END

	---stop adaugare pozitie noua in pozdoc-----
	-----start modificare pozitie existenta in pozdoc----
	IF @update = 1
		OR @subtip = 'SE'
		--situatia in care se modifica o pozitie din pozdoc sau se adauga pozitie cu subtip SE->serie in cadrul pozitiei din pozdoc
	BEGIN
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		IF isnull((
					SELECT max(left(UM_2, 1))
					FROM nomencl
					WHERE cod = @Cod
					), '') = 'Y'
			AND isnull(@Serie, '') <> ''
			AND @Serii <> 0
		BEGIN --daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			SELECT @cod = (CASE WHEN @Cod IS NULL THEN '' ELSE @cod END), @GestPred = (CASE WHEN @GestPred IS NULL THEN '' ELSE @GestPred END
					), @Cantitate = (CASE WHEN @Cantitate IS NULL THEN 0 ELSE @Cantitate END), @CodIntrare = (CASE WHEN @CodIntrare IS NULL THEN '' ELSE @CodIntrare END
					), @GestPrim = (CASE WHEN @GestPrim IS NULL THEN '' ELSE @GestPrim END)

			EXEC wScriuPDserii 'TE', @Numar, @Data, @GestPred, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, @GestPrim

			SET @Cantitate = isnull((
						SELECT SUM(cantitate)
						FROM pdserii
						WHERE tip = 'TE'
							AND Numar = @Numar
							AND data = @Data
							AND Gestiune = @GestPred
							AND cod = @Cod
							AND Gestiune_primitoare = @GestPrim
							AND Cod_intrare = @CodIntrare
							AND Numar_pozitie = @NrPozitie
						), 0) --calcul cantitate pt pozdoc din pdserii
		END

		IF @subtip = 'SE'
		BEGIN --daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
			UPDATE pozdoc
			SET Cantitate = (CASE WHEN isnull(@Cantitate, 0) <> 0 THEN @Cantitate ELSE Cantitate END)
			WHERE subunitate = @Sb
				AND tip = 'TE'
				AND numar = @Numar
				AND data = @Data
				AND numar_pozitie = @NrPozitie
		END
				----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
		ELSE
		begin
			UPDATE pozdoc
			SET Cod = (CASE WHEN @Cod IS NULL THEN Cod ELSE @cod END), Gestiune = (CASE WHEN @GestPred IS NULL THEN Gestiune ELSE @GestPred END
					), Cantitate = (CASE WHEN @Cantitate IS NULL THEN Cantitate ELSE convert(DECIMAL(11, 3), @Cantitate) END
					), Pret_de_stoc = (CASE WHEN @PretSt IS NULL THEN convert(DECIMAL(11, 5), Pret_de_stoc) ELSE convert(DECIMAL(11, 5), @PretSt) END
					), Pret_vanzare = (
					CASE WHEN @PretVanz IS NULL THEN convert(DECIMAL(11, 5), Pret_vanzare) ELSE convert(DECIMAL(11, 5), @PretVanz) 
						END
					), Pret_cu_amanuntul = (
					CASE WHEN @PretAmPrim IS NULL THEN convert(DECIMAL(11, 5), Pret_cu_amanuntul) ELSE convert(DECIMAL(11, 5), 
								@PretAmPrim) END
					), Utilizator = @Utilizator, Data_operarii = convert(DATETIME, convert(CHAR(10), getdate(), 104), 104), 
				Ora_operarii = RTrim(replace(convert(CHAR(8), getdate(), 108), ':', '')), Cod_intrare = (CASE WHEN @CodIntrare IS NULL THEN Cod_intrare ELSE @CodIntrare END
					), Cont_de_stoc = (CASE WHEN @CtStoc IS NULL THEN Cont_de_stoc ELSE @CtStoc END), 
				Cont_corespondent = (CASE WHEN @CtCoresp IS NULL THEN Cont_corespondent ELSE @CtCoresp END), 
				TVA_neexigibil = (CASE WHEN @TVAnx IS NULL THEN convert(DECIMAL(11, 5), TVA_neexigibil) ELSE convert(DECIMAL(11, 5), @TVAnx) END
					), Pret_amanunt_predator = (
					CASE WHEN @PretAmPred IS NULL THEN convert(DECIMAL(11, 5), Pret_amanunt_predator) ELSE convert(DECIMAL(11, 5), 
								@PretAmPred) END
					), Locatie = (CASE WHEN @LocatiePrim IS NULL THEN Locatie ELSE @LocatiePrim END), 
				Data_expirarii = (CASE WHEN @DataExpStoc IS NULL THEN Data_expirarii ELSE @DataExpStoc END), 
				Loc_de_munca = (CASE WHEN @LM IS NULL THEN Loc_de_munca ELSE @LM END), Comanda = (CASE WHEN @Comanda IS NULL THEN Comanda ELSE @Comanda END
					), Barcod = (CASE WHEN @Barcod IS NULL THEN Barcod ELSE @Barcod END), Cont_intermediar = (CASE WHEN @CtInterm IS NULL THEN Cont_intermediar ELSE @CtInterm END
					), Cont_venituri = (CASE WHEN @CtAdPrim IS NULL THEN Cont_venituri ELSE @CtAdPrim END), 
				Discount = (CASE WHEN @DinCust IS NULL THEN convert(DECIMAL(11, 5), Discount) ELSE convert(DECIMAL(11, 5), @DinCust) END
					), Tert = (CASE WHEN @CtAdPred IS NULL THEN Tert ELSE @CtAdPred END), Factura = (CASE WHEN @ComLivr IS NULL THEN Factura ELSE @ComLivr END
					), Gestiune_primitoare = (CASE WHEN @GestPrim IS NULL THEN Gestiune_primitoare ELSE @GestPrim END
					), Numar_DVI = (CASE WHEN @CtTVAnxPred IS NULL THEN Numar_DVI ELSE @CtTVAnxPred END), Stare = (CASE WHEN @Stare IS NULL THEN Stare ELSE @Stare END
					), Grupa = (CASE WHEN @CodIPrim IS NULL THEN Grupa ELSE @CodIPrim END), Cont_factura = (CASE WHEN @CtTVAnxPrim IS NULL THEN Cont_factura ELSE @CtTVAnxPrim END
					), Valuta = (CASE WHEN @Valuta IS NULL THEN Valuta ELSE @Valuta END), Curs = (CASE WHEN @Curs IS NULL THEN Curs ELSE convert(DECIMAL(11, 3), @Curs) END
					), Procent_vama = (CASE WHEN @Schimb IS NULL THEN Procent_vama ELSE @Schimb END), 
				Accize_cumparare = (CASE WHEN @AccCump IS NULL THEN Accize_cumparare ELSE convert(DECIMAL(11, 3), @AccCump) END
					), Accize_datorate = (CASE WHEN @AccDat IS NULL THEN Accize_datorate ELSE convert(DECIMAL(11, 3), @AccDat) END
					), Contract = (CASE WHEN @GestDest IS NULL THEN [Contract] ELSE @GestDest END), Jurnal = (CASE WHEN @Jurnal IS NULL THEN Jurnal ELSE @Jurnal END
					),
				idIntrare=(case when @idIntrare is null then idIntrare else @idIntrare end), 
				idIntrareFirma=(case when @idIntrareFirma is null then idIntrareFirma else @idIntrareFirma end)
			WHERE subunitate = @Sb
				AND tip = 'TE'
				AND numar = @Numar
				AND data = @Data
				AND numar_pozitie = @NrPozitie
			
			SET @docDetalii = (
				SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, 'TE' tip, 'pozdoc' as tabel, @detalii
				for xml raw
				)
			exec wScriuDetalii @parXML=@docDetalii
		end
	END

	-----stop modificare pozitie existenta in pozdoc----
	-- inserez codul de intrare generat la in gestiunea primitoare.
	IF @parXmlScriereIesiri.value('(/row/@cod_intrare_primitor)[1]', 'varchar(50)') IS NULL
		SET @parXmlScriereIesiri.modify(
				'insert attribute cod_intrare_primitor {sql:variable("@CodIPrim")} into (/row)[1]')
	ELSE
		SET @parXmlScriereIesiri.modify('replace value of (/row/@cod_intrare_primitor)[1] with sql:variable("@CodIPrim")'
			)
	-- inserez numarul acordat
	IF @parXmlScriereIesiri.value('(/row/@numar)[1]', 'varchar(20)') IS NULL
		SET @parXmlScriereIesiri.modify(
				'insert attribute numar {sql:variable("@numar")} into (/row)[1]')
	ELSE
		SET @parXmlScriereIesiri.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")'
			)

	/** Tratam ID-ul inserat pentru a-l returna la wScriuPozDoc **/
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))
END TRY

BEGIN CATCH
	--ROLLBACK TRAN
	SET @mesaj = ERROR_MESSAGE()

	RAISERROR (@mesaj, 11, 1)
END CATCH

BEGIN TRY
	EXEC sp_xml_removedocument @iDoc
END TRY

BEGIN CATCH
END CATCH
