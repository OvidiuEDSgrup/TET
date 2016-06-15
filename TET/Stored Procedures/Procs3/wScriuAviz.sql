
--***
CREATE PROCEDURE wScriuAviz @parXmlScriereIesiri XML
OUTPUT AS

BEGIN TRY
	DECLARE @Tip CHAR(2), @Numar varchar(20), @Data DATETIME, @Tert CHAR(13), @PctLiv CHAR(5), @CtFact VARCHAR(40), @Fact CHAR(20), 
		@DataFact DATETIME, @DataScad DATETIME, @Gest CHAR(9), @Cod CHAR(20), @CodIntrare CHAR(13), @Cantitate FLOAT, @PretValuta FLOAT, 
		@Valuta CHAR(3), @Curs FLOAT, @Discount FLOAT, @PretVanz FLOAT, @CotaTVA FLOAT, @SumaTVA FLOAT, @PretAm FLOAT, @CategPret INT, 
		@LM CHAR(9), @Comanda_bugetari CHAR(40), @Comanda CHAR(20), @ComLivr CHAR(20), @Jurnal CHAR(3), @Stare INT, @Barcod CHAR(30), @TipTVAsauSchimb INT, 
		@Suprataxe FLOAT, @Serie CHAR(20), @Utilizator CHAR(10), @CtStoc VARCHAR(40), @ValFact FLOAT, @ValTVA FLOAT, @ValValuta FLOAT, 
		@NrPozitie INT, @PozitieNoua INT, @update BIT, @subtip VARCHAR(2), @mesaj VARCHAR(200), @docInserate XML, @adaos float,
		@dataOperarii datetime, @oraOperarii varchar(50), @tipMiscare char(1), @docDetalii XML, @detalii xml, @areDetalii bit,
		@areIdPozDoc bit, @comandaSql nvarchar(max), @explicatii varchar(50), 
		@Sb CHAR(9), @TPreturi INT, @DiscInv INT, @TLit INT, @Accize INT, @CtAccDB VARCHAR(40), @CtAccCR VARCHAR(40), @DifPProd INT, @Ct378 VARCHAR(40), 
		@AnGest378 INT, @AnGr378 INT, @Ct4428 VARCHAR(40), @AnGest4428 INT, @Ct4427 VARCHAR(40), @Ct4428AV VARCHAR(40), @TipNom CHAR(1), 
		@CtNom VARCHAR(40), @AtribCtNom float, @PStocNom FLOAT, @GrNom CHAR(13), @StLimNom FLOAT, @CoefC2Nom FLOAT, @CategNom INT, @TipGest CHAR(1), 
		@CtGest VARCHAR(40), @CategMFix INT, @ValAmMFix FLOAT, @CtAmMFix VARCHAR(40), @PretSt FLOAT, @TVAnx FLOAT, @PretAmPred FLOAT, 
		@LocatieStoc CHAR(30), @DataExpStoc DATETIME, @DiscAplic FLOAT, @CtCoresp VARCHAR(40), @CtInterm VARCHAR(40), @CtVenit VARCHAR(40), 
		@CtAdPred VARCHAR(40), @CtTVAnxPred VARCHAR(40), @CtTVA VARCHAR(40), @AccCump FLOAT, @AccDat FLOAT, @StersPoz INT, @Bugetar INT, @serii INT,
		@rotunjpretvanz INT, @sumarotpretvanz decimal(17,3),
		@Ct4428LaPlati varchar(40) --Pentru TVA la Incasare
		, @idIntrare int, @idIntrareFirma int
		
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuAvizSP')
		exec wScriuAvizSP @parXmlScriereIesiri output

	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri

	SELECT	@Numar = isnull(numar, ''),
			@Data = data,
			@Tert = ISNULL(tert, ''),
			@PctLiv = ISNULL(punct_livrare, ''),
			@CtFact = cont_factura,
			@Fact = factura,
			@DataFact = data_facturii,
			@DataScad = data_scadentei,
			@Gest = gestiune,
			@Cod = cod,
			@CodIntrare = cod_intrare,
			@Cantitate = cantitate,
			@PretValuta = pret_valuta,
			@Valuta = valuta,
			@Curs = curs,
			@PretVanz = ISNULL(pret_vanzare, 0),
			@Discount = discount,
			@CotaTVA = cota_TVA,
			@SumaTVA = suma_tva,
			@PretAm = pret_amanunt,
			@CategPret = ISNULL(categ_pret, ''),
			@LM = lm,
			@Comanda_bugetari = comanda_bugetari,
			@Comanda = comanda,
			@CtStoc = cont_stoc,
			@ComLivr = contract,
			@CtCoresp= cont_corespondent,
			@Jurnal = jurnal,
			@Stare = stare,
			@Barcod = barcod,
			@LocatieStoc = locatie,
			@DataExpStoc = convert(datetime, data_expirarii, 101),
			@TipTVAsauSchimb = tipTVA,
			@Suprataxe = suprataxe,
			@Serie = isnull(serie, 0),
			@Utilizator = ISNULL(utilizator, ''),
			@NrPozitie = ISNULL(numar_pozitie, 0),
			@update = isnull(ptupdate, 0),
			@tip = tip,
			@subtip = subtip,
			@explicatii = ISNULL(explicatii,''),
			@detalii = detalii

	FROM OPENXML(@iDoc, '/row') 
	WITH (
		tip CHAR(2) '@tip',
		subtip CHAR(2) '@subtip',
		numar varchar(20) '@numar',
		data DATETIME '@data',
		tert CHAR(13) '@tert',
		factura CHAR(20) '@factura',
		data_facturii DATETIME '@data_facturii',
		data_scadentei DATETIME '@data_scadentei',
		cont_factura VARCHAR(40) '@cont_factura',
		gestiune CHAR(9) '@gestiune',
		cod CHAR(20) '@cod',
		cod_intrare CHAR(20) '@cod_intrare',
		cantitate FLOAT '@cantitate',
		valuta VARCHAR(3) '@valuta',
		curs VARCHAR(14) '@curs',
		pret_valuta FLOAT '@pret_valuta',
		discount FLOAT '@discount',
		pret_vanzare FLOAT '@pret_vanzare',
		pret_amanunt FLOAT '@pret_amanunt',
		lm CHAR(9) '@lm',
		comanda_bugetari CHAR(40) '@comanda_bugetari',
		comanda CHAR(20) '@comanda',
		contract CHAR(20) '@contract',
		jurnal CHAR(3) '@jurnal',
		stare INT '@stare',
		barcod CHAR(30) '@barcod',
		locatie varchar(50) '@locatie',
		data_expirarii varchar(50) '@data_expirarii',
		cont_corespondent VARCHAR(40) '@cont_corespondent',
		cont_stoc VARCHAR(40) '@cont_stoc',
		tipTVA INT '@tipTVA',
		utilizator CHAR(20) '@utilizator',
		serie CHAR(20) '@serie',
		suma_tva FLOAT '@suma_tva',
		cota_TVA FLOAT '@cota_TVA',
		numar_pozitie INT '@numar_pozitie',
		suprataxe FLOAT '@suprataxe',
		ptupdate INT '@update',
		explicatii VARCHAR(30) '@explicatii',
		punct_livrare VARCHAR(30) '@punct_livrare',
		categ_pret VARCHAR(30) '@categ_pret',
		detalii XML 'detalii/row'
	)

	SET @Comanda_bugetari = @parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') 
	if @comanda_bugetari is null set @Comanda_bugetari=@comanda
		--din cursor nu stie sa citeasca cu spatiile din fata!

	IF isnull(@utilizator, '') = ''
	BEGIN
		RAISERROR ('Utilizator invalid!', 11, 1)

		RETURN - 1
	END
	
	IF EXISTS (SELECT * FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
		set @areDetalii = 1
	IF EXISTS (SELECT * FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'idPozDoc')
		set @areIdPozDoc = 1
		
	select	@sb='', @TPreturi=0, @DiscInv=0, @TLit=0, @Accize=0, @CtAccDB='', @CtAccCR='', @AnGest378=0, @AnGr378=0, @Ct378='', 
			@AnGest4428=0, @Ct4428='', @Ct4427='', @Ct4428AV='', @DifPProd='', @Bugetar='', @Serii='', @rotunjpretvanz=0, @sumarotpretvanz=0
			
	select	@Sb = (case when Parametru = 'SUBPRO' then rtrim(Val_alfanumerica) else @Sb end),
			@TPreturi = (case when Parametru = 'PRETURI' then Val_logica else @TPreturi end),
			@DiscInv = (case when Parametru = 'INVDISCAP' then Val_logica else @DiscInv end),
			@TLit = (case when Parametru = 'TIMBRULIT' then Val_logica else @TLit end),
			@Accize = (case when Parametru = 'ACCIZE' then Val_logica else @Accize end),
			@CtAccDB = (case when Parametru = 'CCHACCIZE' then rtrim(Val_alfanumerica) else @CtAccDB end),
			@CtAccCR = (case when Parametru = 'CACCIZE' then rtrim(Val_alfanumerica) else @CtAccCR end),
			@AnGest378 = (case when Parametru = 'CADAOS' then Val_logica else @AnGest378 end),
			@AnGr378 = (case when Parametru = 'CADAOS' then Val_numerica else @AnGr378 end),
			@Ct378 = (case when Parametru = 'CADAOS' then rtrim(Val_alfanumerica) else @Ct378 end),
			@AnGest4428 = (case when Parametru = 'CNTVA' then Val_logica else @AnGest4428 end),
			@Ct4428 = (case when Parametru = 'CNTVA' then rtrim(Val_alfanumerica) else @Ct4428 end),
			@Ct4427 = (case when Parametru = 'CCTVA' then rtrim(Val_alfanumerica) else @Ct4427 end),
			@Ct4428AV = (case when Parametru = 'CNEEXREC' then rtrim(Val_alfanumerica) else @Ct4428AV end),
			@DifPProd = (case when Parametru = 'CONT348' then Val_logica else @DifPProd end),
			@Bugetar = (case when Parametru = 'BUGETARI' then Val_logica else @Bugetar end),
			@Serii = (case when Parametru = 'SERII' then Val_logica else @Serii end),
			@rotunjpretvanz = (case when Parametru = 'ROTPRET' then Val_logica else @rotunjpretvanz end), 
			@sumarotpretvanz = (case when Parametru = 'ROTPRET' then Val_numerica else @sumarotpretvanz end),
			@Ct4428LaPlati= (case when Parametru = 'CNTLIBEN' then Val_alfanumerica else @Ct4428LaPlati end)
	from par where Tip_parametru='GE' and Parametru in ('SUBPRO', 'PRETURI', 'INVDISCAP', 'TIMBRULIT', 'ACCIZE', 'CCHACCIZE', 
		'CACCIZE', 'CADAOS', 'CNTVA', 'CCTVA', 'CNEEXREC', 'CONT348', 'BUGETARI', 'SERII','ROTPRET','CNTLIBEN')
		
	IF isnull(@Tip, '') = ''
		SET @Tip = 'AP'

	EXEC iauNrDataDoc @Tip, @Numar OUTPUT, @Data OUTPUT, 0

	IF isnull(@Stare, 0) = 0
		SET @Stare = 3

	IF isnull(@Fact,'')=''
	begin
		declare @lFactVid int
		exec luare_date_par 'GE','NRFACTVID', @lFactVid output, 0, ''
		if @lFactVid=1
			SET @Fact = '' /* va fi completata automat cu nr. documentului in scriuAviz */
		else
			SET @Fact = @Numar
	end


	SELECT @TipNom = '', @CtNom = '', @PStocNom = 0, @GrNom = '', @CoefC2Nom = 0, @CategNom = 0, @StLimNom = 0

	SELECT @TipNom = tip, @CtNom = cont, @PStocNom = pret_stoc, @GrNom = grupa, @CoefC2Nom = Coeficient_conversie_1, @CategNom = categorie
		, @StLimNom = stoc_limita
	FROM nomencl
	WHERE cod = isnull(@Cod, '')

	-- nu resetam variabilele citite din XML. Daca nu se gaseste linie in stoc, le inseram pe acestea
	--SELECT @TipGest = '', @LocatieStoc = '', @DataExpStoc = @Data
	
	IF @TipNom NOT IN ('S', 'F')
	BEGIN
		SELECT @TipGest = tip_gestiune, @CtGest = cont_contabil_specific
		FROM gestiuni
		WHERE subunitate = @Sb
			AND cod_gestiune = isnull(@Gest, '')

		SELECT @PretSt = pret, @CtStoc = (CASE WHEN isnull(@CtStoc, '') = '' THEN cont ELSE @CtStoc END), @TVAnx = 
			tva_neexigibil, @PretAmPred = pret_cu_amanuntul, @LocatieStoc = locatie, @DataExpStoc = data_expirarii, @Suprataxe = (
				CASE WHEN @Tip = 'AC'
						AND @DifPProd = 1
						AND left(@CtGest, 3) = '371' THEN pret_vanzare ELSE isnull(@Suprataxe, 0) END
				)
			, @idIntrare=idIntrare, @idIntrareFirma=idIntrareFirma
		FROM stocuri
		WHERE subunitate = @Sb
			AND tip_gestiune = @TipGest
			AND cod_gestiune = isnull(@Gest, '')
			AND cod = isnull(@Cod, '')
			AND cod_intrare = isnull(@CodIntrare, '')
	END

	-- daca nu am gasit linie in stocuri si nu s-au trimis in XML, initializam variabilele pt. ca sa nu inseram NULL in pozdoc.
	SELECT @TipGest = isnull(@TipGest,''), @LocatieStoc = isnull(@LocatieStoc, ''), @DataExpStoc = isnull(@DataExpStoc, @Data)

	SET @DiscAplic = (
			CASE WHEN @DiscInv = 1 THEN (1 - 100 / (100 + isnull(@Discount, 0))
							) * 100 ELSE isnull(@Discount, 0) END
			)

	IF isnull(@PretVanz, 0) = 0
		SET @PretVanz = isnull(@PretValuta, 0) * (CASE WHEN isnull(@Valuta, '') <> '' THEN isnull(@Curs, 0) ELSE 1 END) * (1 - @DiscAplic / 100)

	IF @rotunjpretvanz = 1 and @sumarotpretvanz <> 0 -- daca este prevazuta o setare de rotunjire pret in lei
		SET @PretVanz = (CASE WHEN convert(decimal(17,5),@PretVanz)%@sumarotpretvanz<@sumarotpretvanz/2.00000 
			THEN @PretVanz-convert(decimal(17,5),@PretVanz)%@sumarotpretvanz 
			ELSE @PretVanz+@sumarotpretvanz-convert(decimal(17,5),@PretVanz)%@sumarotpretvanz END)
	ELSE -- daca nu e setare
		SET @PretVanz = round(@PretVanz, (case when isnull(@Valuta,'')<>'' then 5 else 5 end)) -- a fost cu 2 zecimale la valuta, dar cine doreste rotunjire sa puna setarea!

	IF isnull(@PretAm, 0) = 0
		SET @PretAm = round(convert(DECIMAL(17, 5), convert(DECIMAL(15, 5), round(@PretVanz, 2)) * (1 + isnull(@CotaTVA, 0) / 100
						)), 5)

	IF @TipNom = 'F'
	BEGIN
		SELECT @CtStoc = @CtNom, @PretSt = 0, @CategMFix = 0, @ValAmMFix = 0

		SELECT @CtStoc = cont_mijloc_fix, @PretSt = valoare_de_inventar, @CategMFix = categoria, @ValAmMFix = valoare_amortizata
		FROM fisamf
		WHERE subunitate = @Sb
			AND numar_de_inventar = isnull(@CodIntrare, '')
			AND felul_operatiei = '1'
			AND data_lunii_operatiei BETWEEN (CASE WHEN left(str(@StLimNom), 1) <> '1' THEN dbo.bom(@Data) ELSE '01/01/1901' END
						)
				AND dbo.eom(@Data)

		SET @CtAmMFix = isnull((
					SELECT max(cod_de_clasificare)
					FROM mfix
					WHERE subunitate = 'DENS'
						AND numar_de_inventar = isnull(@CodIntrare, '')
					), '')
	END

	/* La Stornare avans, daca s-a completat factura de avans, caut in tabela facturi contul facturii de avans. Daca este, contul facturii de avans devine cont de stoc. */
	IF @update=0 and @TipNom='S' AND isnull(@CodIntrare, '') <> '' AND @Cantitate<0
			AND EXISTS (SELECT 1 FROM conturi WHERE subunitate = @Sb AND cont = @CtNom AND sold_credit = 2)
		SELECT @CtStoc = fa.Cont_de_tert FROM facturi fa WHERE fa.Subunitate=@Sb and fa.tip=0x46 and fa.Tert=@tert and fa.Factura=@CodIntrare

	IF @PretSt IS NULL
		SET @PretSt = (CASE WHEN @TipNom = 'S' THEN 0 WHEN isnull(@PStocNom, 0)=0 THEN @PretVanz ELSE isnull(@PStocNom, 0) END)

	IF isnull(@CtStoc, '') = ''
		SET @CtStoc = dbo.formezContStoc(isnull(@Gest, ''), isnull(@Cod, ''), isnull(@LM, ''))

	IF @TipNom = 'S'
		AND isnull(@CodIntrare, '') = ''
	begin
		/* Caut in tabela facturi sa vad daca este pe sold o factura de avans. Daca este, punem pe aceeasi factura. */
		select top 1 @CodIntrare=rtrim(factura) from facturi fa 
			where fa.Subunitate=@Sb and fa.tip=0x46 and tert=@Tert
					and ABS(fa.sold)>0.1 and rtrim(fa.Cont_de_tert)=@CtStoc
		
		if isnull(@CodIntrare,'')=''
			SET @CodIntrare = 'AV' + RTrim(replace(convert(varchar(20), @Data, 3), '/', ''))
	end

	IF @Tip <> 'AC'
	BEGIN
		IF isnull(@CtFact, '') = ''
			AND @PctLiv <> ''
			SELECT @CtFact = cont_in_banca3
			FROM infotert
			WHERE subunitate = @Sb
				AND tert = @Tert
				AND identificator = @PctLiv

		IF isnull(@CtFact, '') = ''
			SELECT @CtFact = (CASE WHEN isnull(@CtFact, '') = '' THEN cont_ca_beneficiar ELSE isnull(@CtFact, '') END
					)
			FROM terti
			WHERE subunitate = @Sb
				AND tert = @Tert
	END

	IF @CtFact IS NULL
		SET @CtFact = ''
	/*** Daca cumva nu am CONT_CORESPONDENT pana in acest moment incerc formarea lui **/
	IF ISNULL(@CtCoresp,'')=''
		SET @CtCoresp = (CASE WHEN @TipNom = 'S' THEN @CtFact ELSE dbo.contCorespAP(isnull(@Gest, ''), isnull(@Cod, ''), @CtStoc, isnull(@LM, '')) END)

	IF @TipNom = 'F'
		SET @AccDat = @ValAmMFix

	IF @AccDat IS NULL
		AND @Accize = 1
	BEGIN
		DECLARE @AccCategProd INT, @AccUnitVanz FLOAT

		EXEC luare_date_par 'GE', 'CATEGPRO', @AccCategProd OUTPUT, 0, ''

		SET @AccUnitVanz = isnull((
					SELECT max(acciza_vanzare)
					FROM categprod
					WHERE categoria = @CategNom
					), 0)
		SET @AccDat = round(convert(DECIMAL(17, 4), @CoefC2Nom * @AccUnitVanz * ISNULL(@Cantitate, 0)), 3)
	END

	IF @AccDat IS NULL
		SET @AccDat = 0

	-- tratare TVA neinregistrat cu cota <>0:
	IF isnull(@SumaTVA, 0) = 0
		SET @SumaTVA = round(convert(DECIMAL(17, 4), ISNULL(@Cantitate, 0) * @PretVanz * (CASE WHEN @TipTVAsauSchimb = 2 THEN 0 ELSE isnull(@CotaTVA, 0) END
						) / 100), 2)

	SELECT @ValFact = isnull(@ValFact, 0) + round(convert(DECIMAL(17, 3), ISNULL(@Cantitate, 0) * @PretVanz), 2), @ValTVA = isnull(
			@ValTVA, 0) + @SumaTVA, @ValValuta = isnull(@ValValuta, 0) + (
			CASE WHEN isnull(@Valuta, '') <> '' THEN round(convert(DECIMAL(17, 3), ISNULL(@Cantitate, 0) * isnull(@PretValuta, 0) * (1 - @DiscAplic / 100
									)), 2) ELSE 0 END
			)

	IF isnull(@Utilizator, '') = ''
		SET @Utilizator = dbo.fIaUtilizator(NULL)

	IF @TVAnx IS NULL
		SET @TVAnx = isnull(@CotaTVA, 0)

	SELECT @PretAmPred = (CASE WHEN left(@CtStoc, 3) = '354' THEN @PretSt WHEN @PretAmPred IS NULL THEN @PretAm ELSE @PretAmPred END), 
			@CtInterm = dbo.contIntermAP(isnull(@Gest, ''), isnull(@Cod, ''), @CtStoc, @CtCoresp), 
			@CtVenit = dbo.contVenitAP(isnull(@Gest, ''), isnull(@Cod, ''), @CtStoc, @CtInterm)

	IF @Bugetar = 1
		AND ISNULL(@Comanda_bugetari, '') <> '' -- ind. bug. asociat contului de venituri 
		SET @Comanda_bugetari = left(isnull(@comanda_bugetari, ''), 20) + (
				SELECT Cont_strain
				FROM contcor
				WHERE ContCG = @CtVenit
				)

	IF @TipNom = 'F'
	BEGIN
		DECLARE @Ct681C VARCHAR(40), @N681C INT, @Ct681NC VARCHAR(40), @N681NC INT

		EXEC luare_date_par 'MF', 'CA681', 0, @N681C OUTPUT, @Ct681C OUTPUT

		EXEC luare_date_par 'MF', '681NECORP', 0, @N681NC OUTPUT, @Ct681NC OUTPUT

		SET @CtAdPred = (
				CASE WHEN @CategMFix = 7 THEN RTrim(@Ct681NC) + (
								CASE @N681NC WHEN 2 THEN RTrim(substring(@CtStoc, 3, 11)) WHEN 3 THEN '.' + RTrim(isnull(@LM, '')) ELSE 
										'' END
								) ELSE RTrim(@Ct681C) + (CASE @N681C WHEN 2 THEN RTrim(substring(@CtStoc, 3, 11)) WHEN 3 THEN '.' + RTrim(isnull(@LM, '')) ELSE '' END
							) END
				)
	END

	IF @CtAdPred IS NULL
		AND (
			@TLit = 1
			OR @Accize = 1
			)
		SET @CtAdPred = @CtAccDB

	IF @CtAdPred IS NULL
		AND (
			left(@CtStoc, 3) = '371'
			OR left(@CtStoc, 2) = '35'
			)
		SET @CtAdPred = RTrim(@Ct378) + (CASE WHEN @AnGest378 = 1 THEN '.' + RTrim(isnull(@Gest, '')) ELSE '' END) + (CASE WHEN @AnGr378 = 1 THEN '.' + RTrim(@GrNom) ELSE '' END
				)
	ELSE
		SET @CtAdPred = ''

	IF @TipNom = 'F'
		SET @CtTVAnxPred = @CtAmMFix

	IF @CtTVAnxPred IS NULL
		AND (
			@TLit = 1
			OR @Accize = 1
			)
		SET @CtTVAnxPred = @CtAccCR

	IF @CtTVAnxPred IS NULL
		AND (
			left(@CtStoc, 3) = '371'
			OR left(@CtStoc, 2) = '35'
			)
		SET @CtTVAnxPred = RTrim(@Ct4428) + (CASE WHEN @AnGest4428 = 1 THEN '.' + RTrim(isnull(@Gest, '')) ELSE '' END)
	ELSE
		SET @CtTVAnxPred = ''
	/*Tva la Incasare*/
	declare @TLI int
	select top 1 @TLI=(case when tip_tva='I' then 1 else 0 end)
		from TvaPeTerti where tipf='B' and tert is null and @datafact>dela
		order by dela desc

	if @TLI is null
		set @TLI=0

	SET @CtTVA = (CASE WHEN left(@CtFact, 3) = '418' THEN @Ct4428AV 
					when @TLI=1 and @data>'12/31/2012' then @Ct4428LaPlati 
					ELSE @Ct4427 END)
	SET @AccCump = (
			CASE WHEN @Accize = 1
					OR @TipNom = 'F' THEN 0 WHEN @TLit = 1 THEN @PretAmPred ELSE @CategPret END
			)
	
	-- setez variabile valabile pt. insert si update
	select 	@adaos = (CASE WHEN @PretSt > 0 THEN round(convert(DECIMAL(17, 3), (@PretVanz / @PretSt - 1) * 100), 2) ELSE 0 END),
			@dataOperarii = convert(DATETIME, convert(CHAR(10), getdate(), 104), 104),
			@oraOperarii = RTrim(replace(convert(CHAR(8), getdate(), 108), ':', ''))
				
	
	---start adaugare pozitie noua in pozdoc-----
	IF @update = 0
		AND @subtip <> 'SE'
	BEGIN
		IF @NrPozitie = 0
		BEGIN
			EXEC luare_date_par 'AP', 'POZITIE', 0, @NrPozitie OUTPUT, '' --alocare numar pozitie

			SET @NrPozitie = @NrPozitie + 1

			EXEC setare_par 'AP', 'POZITIE', NULL, NULL, @NrPozitie, NULL 
				--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
		END

		-->>>>>>>>>start cod pentru lucrul cu serii<<<<<<<<<<<<<<--
		IF @Serii <> 0
			AND isnull((
					SELECT max(left(UM_2, 1))
					FROM nomencl
					WHERE cod = isnull(@Cod, '')
					), '') = 'Y'
			AND isnull(@Serie, '') <> ''
		BEGIN --daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			SELECT @cod = (CASE WHEN @Cod IS NULL THEN '' ELSE @cod END), @Gest = (CASE WHEN @Gest IS NULL THEN '' ELSE @Gest END), 
				@Cantitate = (CASE WHEN @Cantitate IS NULL THEN 0 ELSE @Cantitate END), 
				@CodIntrare = (CASE WHEN @CodIntrare IS NULL THEN '' ELSE @CodIntrare END)

			EXEC wScriuPDserii @Tip, @Numar, @Data, @Gest, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''

			SET @Cantitate = (
					SELECT SUM(cantitate)
					FROM pdserii
					WHERE tip = @Tip
						AND Numar = @Numar
						AND data = @Data
						AND Gestiune = isnull(@Gest, '')
						AND cod = isnull(@Cod, '')
						AND Cod_intrare = isnull(@CodIntrare, '')
						AND Numar_pozitie = @NrPozitie
					) --calcul cantitate pt pozdoc din pdserii
		END

		-->>>>>>>>>stop cod pentru lucrul cu serii<<<<<<<<<<<<<<<--
		IF OBJECT_ID('tempdb..#APInserat') IS NOT NULL
			DROP TABLE #APInserat

		CREATE TABLE #APInserat (idPozDoc INT)
		
		
		select	@Cod = isnull(@Cod, ''),
				@Gest = isnull(@Gest, ''),
				@Cantitate = ISNULL(@Cantitate, 0),
				@PretValuta = isnull(@PretValuta, 0),
				@CotaTVA = isnull(@CotaTVA, 0),
				@CodIntrare = isnull(@CodIntrare, ''),
				@tipMiscare = (CASE WHEN isnull(@TipNom, '') IN ('F', 'S', 'R') THEN 'V' ELSE 'E' END),
				@LM = isnull(@LM, ''),
				@Comanda_bugetari = isnull(@Comanda_bugetari, ''),
				@Barcod = isnull(@Barcod, ''),
				@Discount = isnull(@Discount, 0),
				@Valuta = isnull(@Valuta, ''),
				@Curs = isnull(@Curs, 0),
				@Suprataxe = isnull(@Suprataxe, 0),
				@ComLivr = isnull(@ComLivr, ''),
				@Jurnal = isnull(@Jurnal, '')
		
		SET @comandaSql = N'
			INSERT pozdoc (
				Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, 
				Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
				Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
				Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
				Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, 
				Accize_datorate, Contract, Jurnal,subtip'+(case when @areDetalii=1 then ', detalii' else '' end)+', idIntrare, idIntrareFirma
				)
			' + (case when @areIdPozDoc =1 then 'OUTPUT inserted.idPozDoc INTO #APInserat(idPozDoc)' else '' end) +'
			VALUES (
				@Sb, @Tip, @Numar, @cod, @Data, @gest, convert(decimal(17,5),@Cantitate), @PretValuta, @PretSt, 
				@adaos, @PretVanz, @PretAm, @SumaTVA, @CotaTVA, @Utilizator, @dataOperarii, @oraOperarii, 
				@CodIntrare, @CtStoc, @CtCoresp, @TVAnx, @PretAmPred, @tipMiscare, @LocatieStoc, @DataExpStoc, @NrPozitie, 
				@LM, @Comanda_bugetari, @Barcod, @CtInterm, @CtVenit, @Discount, @Tert, @Fact, @CtAdPred, space(13) + @PctLiv, @Stare, 
				@CtTVA, @CtFact, @Valuta, @Curs, @DataFact, @DataScad, @TipTVAsauSchimb, @Suprataxe, @AccCump, 
				@AccDat, @ComLivr, @Jurnal,(case when @subtip=@tip then null else @subtip end)'+(case when @areDetalii=1 then ', @detalii' else '' end)+', @idIntrare, @idIntrareFirma)'

		exec sp_executesql @statement=@comandaSql, @params=N'@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar varchar(20), @Cod CHAR(20), 
			@Data DATETIME, @Gest CHAR(9), @Cantitate FLOAT, @PretValuta FLOAT, @PretSt FLOAT, @adaos float, @PretVanz FLOAT, 
			@PretAm FLOAT, @SumaTVA FLOAT, @CotaTVA FLOAT, @Utilizator CHAR(10), @dataOperarii datetime, @oraOperarii varchar(50), 
			@CodIntrare CHAR(13), @CtStoc VARCHAR(40), @CtCoresp VARCHAR(40), @TVAnx FLOAT, @PretAmPred FLOAT, @tipMiscare char(1), @LocatieStoc CHAR(30), 
			@DataExpStoc DATETIME, @NrPozitie INT, @LM CHAR(9), @Comanda_bugetari CHAR(40), @Barcod CHAR(30), @CtInterm VARCHAR(40), @CtVenit VARCHAR(40), 
			@Discount FLOAT, @Tert CHAR(13), @Fact CHAR(20), @CtAdPred VARCHAR(40), @CtTVAnxPred VARCHAR(40), @PctLiv CHAR(5), @Stare INT, 
			@CtTVA VARCHAR(40), @CtFact VARCHAR(40), @Valuta CHAR(3), @Curs FLOAT, @DataFact DATETIME, @DataScad DATETIME, @TipTVAsauSchimb INT, 
			@Suprataxe FLOAT, @AccCump FLOAT, @AccDat FLOAT, @ComLivr CHAR(20), @Jurnal CHAR(3),@subtip varchar(2), @idIntrare int, @idIntrareFirma int',
			@detalii = @detalii, @Sb=@Sb, @Tip=@Tip, @Numar=@Numar, @cod=@cod, @Data=@Data, @gest=@gest, @Cantitate=@Cantitate, @PretValuta=@PretValuta, 
			@PretSt=@PretSt, @adaos=@adaos, @PretVanz=@PretVanz, @PretAm=@PretAm, @SumaTVA=@SumaTVA, @CotaTVA=@CotaTVA, @Utilizator=@Utilizator, 
			@dataOperarii=@dataOperarii, @oraOperarii=@oraOperarii, @CodIntrare=@CodIntrare, @CtStoc=@CtStoc, @CtCoresp=@CtCoresp, @TVAnx=@TVAnx, 
			@PretAmPred=@PretAmPred, @tipMiscare=@tipMiscare, @LocatieStoc=@LocatieStoc, @DataExpStoc=@DataExpStoc, @NrPozitie=@NrPozitie, 
			@LM=@LM, @Comanda_bugetari=@Comanda_bugetari, @Barcod=@Barcod, @CtInterm=@CtInterm, @CtVenit=@CtVenit, @Discount=@Discount, @Tert=@Tert, @Fact=@Fact, 
			@CtAdPred=@CtAdPred, @CtTVAnxPred=@CtTVAnxPred, @PctLiv=@PctLiv, @Stare=@Stare, @CtTVA=@CtTVA, @CtFact=@CtFact, 
			@Valuta=@Valuta, @Curs=@Curs, @DataFact=@DataFact, @DataScad=@DataScad, @TipTVAsauSchimb=@TipTVAsauSchimb, @Suprataxe=@Suprataxe, 
			@AccCump=@AccCump, @AccDat=@AccDat, @ComLivr=@ComLivr, @Jurnal=@Jurnal,@subtip=@subtip, @idIntrare= @idIntrare, @idIntrareFirma = @idIntrareFirma

		SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #APInserat
				FOR XML raw, root('Inserate')
				)
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
					WHERE cod = isnull(@Cod, '')
					), '') = 'Y'
			AND isnull(@Serie, '') <> ''
			AND @Serii <> 0
		BEGIN --daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			SELECT @cod = (CASE WHEN @Cod IS NULL THEN '' ELSE @cod END), @Gest = (CASE WHEN @Gest IS NULL THEN '' ELSE @Gest END
					), @Cantitate = (CASE WHEN @Cantitate IS NULL THEN 0 ELSE @Cantitate END), @CodIntrare = (CASE WHEN @CodIntrare IS NULL THEN '' ELSE @CodIntrare END
					)

			EXEC wScriuPDserii @Tip, @Numar, @Data, @Gest, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''

			SET @Cantitate = isnull((
						SELECT SUM(cantitate)
						FROM pdserii
						WHERE tip = @Tip
							AND Numar = @Numar
							AND data = @Data
							AND Gestiune = isnull(@Gest, '')
							AND cod = isnull(@Cod, '')
							AND Cod_intrare = isnull(@CodIntrare, '')
							AND Numar_pozitie = @NrPozitie
						), 0) --calcul cantitate pt pozdoc din pdserii
		END

		IF @subtip = 'SE'
		BEGIN --daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
			UPDATE pozdoc
			SET Cantitate = (CASE WHEN isnull(@Cantitate, 0) <> 0 THEN @Cantitate ELSE Cantitate END)
			WHERE subunitate = @Sb
				AND tip = @tip
				AND numar = @Numar
				AND data = @Data
				AND numar_pozitie = @NrPozitie
		END
				----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
		ELSE
		begin
			SET @comandaSql = N'
				UPDATE pozdoc
				SET  Adaos = @adaos' +
					', Utilizator = @Utilizator' +
					', Data_operarii = @dataOperarii' +
					', Ora_operarii = @oraOperarii' +
					(CASE WHEN @Cod IS NOT NULL THEN ', Cod = @cod' ELSE '' END) +
					(CASE WHEN @Gest IS NOT NULL THEN ', Gestiune = @Gest' ELSE '' END) +
					(CASE WHEN @Cantitate IS NOT NULL THEN ', Cantitate = convert(DECIMAL(11, 5), @Cantitate)' ELSE '' END) +
					(CASE WHEN @PretValuta IS NOT NULL THEN ', Pret_valuta = convert(DECIMAL(11, 5), @PretValuta)' ELSE '' END) +
					(CASE WHEN @PretSt IS NOT NULL THEN ', Pret_de_stoc = convert(DECIMAL(11, 5), @PretSt)' ELSE '' END) +
					(CASE WHEN @PretVanz IS NOT NULL THEN ', Pret_vanzare = convert(DECIMAL(11, 5), @PretVanz)' ELSE '' END) +
					(CASE WHEN @PretAm IS NOT NULL THEN ', Pret_cu_amanuntul = convert(DECIMAL(11, 5), @PretAm)' ELSE '' END) +
					(CASE WHEN @SumaTVA IS NOT NULL THEN ', TVA_deductibil = convert(DECIMAL(11, 5), @SumaTVA)' ELSE '' END) +
					(CASE WHEN @CotaTVA IS NOT NULL THEN ', Cota_TVA = convert(DECIMAL(11, 5), @CotaTVA)' ELSE '' END) +
					(CASE WHEN @CodIntrare IS NOT NULL THEN ', Cod_intrare = @CodIntrare' ELSE '' END) +
					(CASE WHEN @CtStoc IS NOT NULL THEN ', Cont_de_stoc = @CtStoc' ELSE '' END) +
					(CASE WHEN @CtCoresp IS NOT NULL THEN ', Cont_corespondent = @CtCoresp' ELSE '' END) +
					(CASE WHEN @TVAnx IS NOT NULL THEN ', TVA_neexigibil = convert(DECIMAL(11, 5), @TVAnx)' ELSE '' END) +
					(CASE WHEN @PretAmPred IS NOT NULL THEN ', Pret_amanunt_predator = convert(DECIMAL(11, 5), @PretAmPred)' ELSE '' END) +
					(CASE WHEN @LocatieStoc IS NOT NULL THEN ', Locatie = @LocatieStoc' ELSE '' END) +
					(CASE WHEN @DataExpStoc IS NOT NULL THEN ', Data_expirarii = @DataExpStoc' ELSE '' END) +
					(CASE WHEN @LM IS NOT NULL THEN ', Loc_de_munca = @LM' ELSE '' END) +
					(CASE WHEN @Comanda_bugetari IS NOT NULL THEN ', Comanda = @Comanda_bugetari' ELSE '' END) +
					(CASE WHEN @Barcod IS NOT NULL THEN ', Barcod = @Barcod' ELSE '' END) +
					(CASE WHEN @CtInterm IS NOT NULL THEN ', Cont_intermediar = @CtInterm' ELSE '' END) +
					(CASE WHEN @CtVenit IS NOT NULL THEN ', Cont_venituri = @CtVenit' ELSE '' END) +
					(CASE WHEN @Discount IS NOT NULL THEN ', Discount = convert(DECIMAL(11, 5), @Discount)' ELSE '' END) +
					(CASE WHEN @Fact IS NOT NULL THEN ', Factura = @Fact' ELSE '' END) +
					(CASE WHEN @CtAdPred IS NOT NULL THEN ', Gestiune_primitoare = @CtAdPred' ELSE '' END) +
					(CASE WHEN @PctLiv is not null THEN ', Numar_DVI = space(13) + @PctLiv' ELSE '' END) +
					(CASE WHEN @Stare IS NOT NULL THEN ', Stare = @Stare' ELSE '' END) +
					(CASE WHEN @CtTVA IS NOT NULL THEN ', Grupa = @CtTVA' ELSE '' END) +
					(CASE WHEN @CtFact IS NOT NULL THEN ', Cont_factura = @CtFact' ELSE '' END) +
					(CASE WHEN @Valuta IS NOT NULL THEN ', Valuta = @Valuta' ELSE '' END) +
					(CASE WHEN @Curs IS NOT NULL THEN ', Curs = convert(DECIMAL(11, 4), @Curs)' ELSE '' END) +
					(CASE WHEN @DataFact IS NOT NULL THEN ', Data_facturii = @DataFact' ELSE '' END) +
					(CASE WHEN @DataScad IS NOT NULL THEN ', Data_scadentei = @DataScad' ELSE '' END) +
					(CASE WHEN @TipTVAsauSchimb IS NOT NULL THEN ', Procent_vama = @TipTVAsauSchimb' ELSE '' END) +
					(CASE WHEN @Suprataxe IS NOT NULL THEN ', Suprataxe_vama = convert(DECIMAL(11, 3), @Suprataxe)' ELSE '' END) +
					(CASE WHEN @AccCump IS NOT NULL THEN ', Accize_cumparare = convert(DECIMAL(11, 3), @AccCump)' ELSE '' END) +
					(CASE WHEN @AccDat IS NOT NULL THEN ', Accize_datorate = convert(DECIMAL(11, 3), @AccDat)' ELSE '' END) +
					(CASE WHEN @ComLivr IS NOT NULL THEN ', Contract = @ComLivr' ELSE '' END) +
					(CASE WHEN @Jurnal IS NOT NULL THEN ', Jurnal = @Jurnal' ELSE '' END) +
					(CASE WHEN @areDetalii=1 THEN ', detalii = @detalii' else '' end)+
					',idIntrare=@idIntrare' + 
					',idIntrareFirma=@idIntrareFirma' + 
				N'	
				WHERE subunitate = @Sb
					AND tip = @tip
					AND numar = @Numar
					AND data = @Data
					AND numar_pozitie = @NrPozitie
			'
			
			exec sp_executesql @statement=@comandaSql, @params=N'@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar varchar(20), @Cod CHAR(20), 
			@Data DATETIME, @Gest CHAR(9), @Cantitate FLOAT, @PretValuta FLOAT, @PretSt FLOAT, @adaos float, @PretVanz FLOAT, 
			@PretAm FLOAT, @SumaTVA FLOAT, @CotaTVA FLOAT, @Utilizator CHAR(10), @dataOperarii datetime, @oraOperarii varchar(50), 
			@CodIntrare CHAR(13), @CtStoc VARCHAR(40), @CtCoresp VARCHAR(40), @TVAnx FLOAT, @PretAmPred FLOAT, @tipMiscare char(1), @LocatieStoc CHAR(30), 
			@DataExpStoc DATETIME, @NrPozitie INT, @LM CHAR(9), @Comanda_bugetari CHAR(40), @Barcod CHAR(30), @CtInterm VARCHAR(40), @CtVenit VARCHAR(40), 
			@Discount FLOAT, @Tert CHAR(13), @Fact CHAR(20), @CtAdPred VARCHAR(40), @CtTVAnxPred VARCHAR(40), @PctLiv CHAR(5), @Stare INT, 
			@CtTVA VARCHAR(40), @CtFact VARCHAR(40), @Valuta CHAR(3), @Curs FLOAT, @DataFact DATETIME, @DataScad DATETIME, @TipTVAsauSchimb INT, 
			@Suprataxe FLOAT, @AccCump FLOAT, @AccDat FLOAT, @ComLivr CHAR(20), @Jurnal CHAR(3), @idIntrare int, @idIntrareFirma int',
			@detalii = @detalii, @Sb=@Sb, @Tip=@Tip, @Numar=@Numar, @cod=@cod, @Data=@Data, @gest=@gest, @Cantitate=@Cantitate, @PretValuta=@PretValuta, 
			@PretSt=@PretSt, @adaos=@adaos, @PretVanz=@PretVanz, @PretAm=@PretAm, @SumaTVA=@SumaTVA, @CotaTVA=@CotaTVA, @Utilizator=@Utilizator, 
			@dataOperarii=@dataOperarii, @oraOperarii=@oraOperarii, @CodIntrare=@CodIntrare, @CtStoc=@CtStoc, @CtCoresp=@CtCoresp, @TVAnx=@TVAnx, 
			@PretAmPred=@PretAmPred, @tipMiscare=@tipMiscare, @LocatieStoc=@LocatieStoc, @DataExpStoc=@DataExpStoc, @NrPozitie=@NrPozitie, 
			@LM=@LM, @Comanda_bugetari=@Comanda_bugetari, @Barcod=@Barcod, @CtInterm=@CtInterm, @CtVenit=@CtVenit, @Discount=@Discount, @Tert=@Tert, @Fact=@Fact, 
			@CtAdPred=@CtAdPred, @CtTVAnxPred=@CtTVAnxPred, @PctLiv=@PctLiv, @Stare=@Stare, @CtTVA=@CtTVA, @CtFact=@CtFact, 
			@Valuta=@Valuta, @Curs=@Curs, @DataFact=@DataFact, @DataScad=@DataScad, @TipTVAsauSchimb=@TipTVAsauSchimb, @Suprataxe=@Suprataxe, 
			@AccCump=@AccCump, @AccDat=@AccDat, @ComLivr=@ComLivr, @Jurnal=@Jurnal, @idIntrare= @idIntrare, @idIntrareFirma = @idIntrareFirma
		end
	END

	---stop modificare pozitie existenta in pozdoc---		
	---returnare parametri in @parXmlScriereIesiri ---
	-->suma_tva
	IF @parXmlScriereIesiri.value('(/row/@suma_tva)[1]', 'varchar(50)') IS NULL
		SET @parXmlScriereIesiri.modify('insert attribute suma_tva {sql:variable("@SumaTVA")} into (/row)[1]')
	ELSE
		SET @parXmlScriereIesiri.modify('replace value of (/row/@suma_tva)[1] with sql:variable("@SumaTVA")')

	-->numar_pozitie	
	IF @parXmlScriereIesiri.value('(/row/@numar_pozitie)[1]', 'int') IS NULL
		SET @parXmlScriereIesiri.modify('insert attribute numar_pozitie {sql:variable("@NrPozitie")} into (/row)[1]')
	ELSE
		SET @parXmlScriereIesiri.modify('replace value of (/row/@numar_pozitie)[1] with sql:variable("@NrPozitie")')

	-->cont_venituri	
	IF @parXmlScriereIesiri.value('(/row/@cont_venituri)[1]', 'varchar(40)') IS NULL
		SET @parXmlScriereIesiri.modify('insert attribute cont_venituri {sql:variable("@CtVenit")} into (/row)[1]')
	ELSE
		SET @parXmlScriereIesiri.modify('replace value of (/row/@cont_venituri)[1] with sql:variable("@CtVenit")')
	-- inserez numarul acordat
	IF @parXmlScriereIesiri.value('(/row/@numar)[1]', 'varchar(20)') IS NULL
		SET @parXmlScriereIesiri.modify(
				'insert attribute numar {sql:variable("@numar")} into (/row)[1]')
	ELSE
		SET @parXmlScriereIesiri.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")')
	---stop returnare parametrii in @parXmlScriereIesiri---	
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))
END TRY

BEGIN CATCH
	--ROLLBACK TRAN
	SET @mesaj = ERROR_MESSAGE()+' (wScriuAviz)'

	RAISERROR (@mesaj, 11, 1)
END CATCH

BEGIN TRY
	EXEC sp_xml_removedocument @iDoc
END TRY

BEGIN CATCH
END CATCH
