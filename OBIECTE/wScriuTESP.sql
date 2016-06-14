--***
IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wScriuTESP'
		)
	DROP PROCEDURE wScriuTESP
GO

--***
CREATE PROCEDURE wScriuTESP @parXmlScriereIesiri XML
OUTPUT AS

BEGIN TRY/*SP
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuTESP')
		exec wScriuTESP @parXmlScriereIesiri output --SP*/

	DECLARE @tip varchar(2), @Numar CHAR(8), @Data DATETIME, @GestPred CHAR(9), @GestPrim CHAR(9), @GestDest CHAR(20), 
		@Cod CHAR(20), @CodIntrare CHAR(13), @CodIPrim CHAR(13), @Cantitate FLOAT, @LocatiePrim CHAR(30), @PretAmPrim FLOAT, @CategPret INT, @Valuta CHAR(3), 
		@Curs FLOAT, @LM CHAR(9), @Comanda CHAR(40), @ComLivr CHAR(20), @Jurnal CHAR(3), @Stare INT, @Barcod CHAR(30), @Schimb INT, 
		@Serie CHAR(20), @Utilizator CHAR(10), @PastrCtSt INT, @Valoare FLOAT, @TotCant FLOAT, @NrPozitie INT, @CtCoresp VARCHAR(20), 
		@CtIntermediar VARCHAR(20), @TVAnx FLOAT, @update BIT, @subtip VARCHAR(2), @mesaj VARCHAR(200), @iDoc INT, @docInserate XML,
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
			tip CHAR(2) '@tip', subtip CHAR(2) '@subtip', numar CHAR(8) '@numar', data DATETIME '@data', tert CHAR(13) '@tert', factura CHAR(20) 
			'@factura', data_facturii DATETIME '@data_facturii', data_scadentei DATETIME '@data_scadentei', cont_factura CHAR(13
			) '@cont_factura', gestiune CHAR(9) '@gestiune', cod CHAR(20) '@cod', cod_intrare CHAR(20) '@cod_intrare', codiPrim CHAR
			(20) '@codiPrim', cantitate FLOAT '@cantitate', valuta VARCHAR(3) '@valuta', curs VARCHAR(14) '@curs', pret_valuta FLOAT 
			'@pret_valuta', discount FLOAT '@discount', pret_amanunt FLOAT '@pret_amanunt', lm CHAR(9) '@lm', comanda_bugetari CHAR
			(40) '@comanda_bugetari', comanda CHAR	(20) '@comanda', contract CHAR(20) '@contract', jurnal CHAR(3) '@jurnal', 
			stare INT '@stare', barcod CHAR(30) 
			'@barcod', tipTVA INT '@tipTVA', utilizator CHAR(20) '@utilizator', serie CHAR(20) '@serie', suma_tva FLOAT '@suma_tva', 
			cota_TVA FLOAT '@cota_TVA', locatie CHAR(30) '@locatie',
			locatieprim char(30) '@locatieprim',
			 numar_pozitie INT '@numar_pozitie', suprataxe FLOAT 
			'@suprataxe', cont_corespondent VARCHAR(20) '@cont_corespondent', contintermediar VARCHAR(20) '@contintermediar', 
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

	DECLARE @Sb CHAR(9), @TabPreturi INT, @TLitR INT, @Accize INT, @CtAccCR VARCHAR(20), @FaraTVAnx INT, @Ct348 VARCHAR(20), @DifPProd INT, 
		@CtIntTE VARCHAR(20), @Ct378 VARCHAR(20), @AnGest378 INT, @AnGr378 INT, @Ct4428 VARCHAR(20), @AnGest4428 INT, @TipNom CHAR(1), 
		@CtNom VARCHAR(20), @PStocNom FLOAT, @PAmNom FLOAT, @GrNom CHAR(13), @CoefConv2Nom FLOAT, @CategNom INT, @GreutSpecNom FLOAT, @TVANom 
		FLOAT, @TipGestPred CHAR(1), @TipGestPrim CHAR(1), @CtGestPrim VARCHAR(20), @PretSt FLOAT, @CtStoc VARCHAR(20), @PretAmPred FLOAT, 
		@LocatieStoc CHAR(30), @DataExpStoc DATETIME, @DinCust INT, @PVanzSt FLOAT, @PAmPreturi FLOAT, @PVanzPreturi FLOAT, 
		@PretVanz FLOAT, @CtInterm VARCHAR(20), @CtAdPred VARCHAR(20), @CtAdPrim VARCHAR(20), @CtTVAnxPred VARCHAR(20), @CtTVAnxPrim VARCHAR(20), 
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
	DECLARE @GestPredCustodie int
	SELECT @TipGestPred = tip_gestiune --/*sp
		,@GestPredCustodie=isnull(detalii.value('(/row/@custodie)[1]','int'),0)--sp*/
	FROM gestiuni
	WHERE subunitate = @Sb
		AND cod_gestiune = @GestPred

	SET @TipGestPrim = ''
	SET @CtGestPrim = ''

	DECLARE @GestPrimCustodie int
	SELECT @TipGestPrim = tip_gestiune, @CtGestPrim = cont_contabil_specific--/*sp
		,@GestPrimCustodie=isnull(detalii.value('(/row/@custodie)[1]','int'),0)--sp*/
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

	--IF isnull(@CodIPrim, '') = ''
	--	-- mai jos, unde a fost trimis parametrul @Data am pus '1901-01-01' (in 2 locuri), pentru a verifica intreg stocul la primitor, nu doar cel cu data egala cu data documentului
	--	SET @CodIPrim = dbo.cautareCodIntrare(isnull(@Cod, ''), isnull(@GestPrim, ''), @TipGestPrim, isnull(@CodIntrare, ''), 
	--			@PretSt, @PretAmPrim, isnull(@CtCoresp, ''),/*SP @AcCodIPrimitor SP*/ 
	--			(CASE WHEN @GestPrimCustodie=1 and @Cantitate>=0.001 THEN 0 
	--				WHEN @GestPredCustodie=1 and @Cantitate<-0.001 THEN 0 
	--				ELSE @AcCodIPrimitor END), 
	--			0, '1901-01-01', '1901-01-01', '', '', @Comanda, @ComLivr, '', '')

	---- inserez codul de intrare generat la in gestiunea primitoare.
	--IF @parXmlScriereIesiri.value('(/row/@codiPrim)[1]', 'varchar(20)') IS NULL
	--	SET @parXmlScriereIesiri.modify('insert attribute codiPrim {sql:variable("@CodIPrim")} into (/row)[1]')
	--ELSE
	--	SET @parXmlScriereIesiri.modify('replace value of (/row/@codiPrim)[1] with sql:variable("@CodIPrim")')
	declare @locatie_detalii varchar(30)
	select @locatie_detalii=@parXmlScriereIesiri.value('(/row/detalii/row/@locatie)[1]','varchar(30)')

	if isnull(@locatie_detalii,'')<>'' and (@GestPrimCustodie=1 and @Cantitate>0.001 or @GestPredCustodie=1 and @Cantitate<-0.001)
		IF @parXmlScriereIesiri.value('(/row/@locatieprim)[1]', 'varchar(20)') IS NULL
			SET @parXmlScriereIesiri.modify('insert attribute locatieprim {sql:variable("@locatie_detalii")} into (/row)[1]')
		ELSE
			SET @parXmlScriereIesiri.modify('replace value of (/row/@locatieprim)[1] with sql:variable("@locatie_detalii")')
	/*begin
		if abs(isnull(@PretValuta,0))>=0.00001 
		begin
			declare @pret_valuta_dec decimal(17,5)
			set @pret_valuta_dec=0
				
			if @parXmlScriereIesiri.value('(/row/@pret_valuta)[1]','float') is null
				set @parXmlScriereIesiri.modify ('insert attribute pret_valuta {sql:variable("@pret_valuta_dec")} into (/row)[1]')
			else
				set @parXmlScriereIesiri.modify('replace value of (/row/@pret_valuta)[1] with sql:variable("@pret_valuta_dec")')		
		end
		
		if abs(isnull(@PretVanz,0))>=0.00001
		begin
			declare @pret_vanzare_dec decimal(17,5)
			set @pret_vanzare_dec=0
				
			if @parXmlScriereIesiri.value('(/row/@pret_vanzare)[1]','float') is null
				set @parXmlScriereIesiri.modify ('insert attribute pret_vanzare {sql:variable("@pret_vanzare_dec")} into (/row)[1]')
			else
				set @parXmlScriereIesiri.modify('replace value of (/row/@pret_vanzare)[1] with sql:variable("@pret_vanzare_dec")')		
		end
	end*/
	-- inserez numarul acordat
	--IF @parXmlScriereIesiri.value('(/row/@numar)[1]', 'varchar(8)') IS NULL
	--	SET @parXmlScriereIesiri.modify(
	--			'insert attribute numar {sql:variable("@numar")} into (/row)[1]')
	--ELSE
	--	SET @parXmlScriereIesiri.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")'
	--		)
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
