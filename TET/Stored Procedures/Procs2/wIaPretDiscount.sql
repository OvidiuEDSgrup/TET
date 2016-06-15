
--***
CREATE PROCEDURE wIaPretDiscount @parXML XML, @Pret FLOAT
OUTPUT, @Discount FLOAT
OUTPUT AS

BEGIN TRY
	/** 
		Se sugereaza pret si, respectiv, discount doar daca la intrare @pret=null si @discount=null
	**/
	DECLARE @Cod CHAR(20), @Data DATETIME, @Tert CHAR(13), @ComandaLivrare CHAR(20), @CategPret INT, @IauPretAmanunt INT, 
		@DocumentInValuta INT, @Sb CHAR(9), @TabelaPreturi INT, @DiscGrupeContr INT, @AnulareDiscount INT, @GrupaNom CHAR(13), 
		@TipCategorie INT, @CategorieInValuta INT, @PretReferinta FLOAT, @PretLuatInValuta INT, @mesaj VARCHAR(600),@ora char(8),
		@CategReferinta int

	SET @Cod = isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), '')
	SET @Data = isnull(@parXML.value('(/row/@data)[1]', 'datetime'), convert(DATETIME, convert(CHAR(10), getdate(), 101), 101))
	SET @Tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), '')
	SET @ComandaLivrare = isnull(@parXML.value('(/row/@comandalivrare)[1]', 'varchar(20)'), '')
	SET @CategPret = isnull(@parXML.value('(/row/@categpret)[1]', 'int'), 0)
	SET @IauPretAmanunt = isnull(@parXML.value('(/row/@iaupretamanunt)[1]', 'int'), 0)
	SET @DocumentInValuta = isnull(@parXML.value('(/row/@documentinvaluta)[1]', 'int'), 0)
	set @ora=replace(convert(char(10),getdate(),108),':','') --Ora exacta a SERVERULUI pentru preturi promotionale ora

	SELECT @Sb = '', @TabelaPreturi = 0, @DiscGrupeContr = 0

	SELECT @Sb = (
			CASE WHEN tip_parametru = 'GE'
					AND parametru = 'SUBPRO' THEN val_alfanumerica ELSE @Sb END
			), 
			@TabelaPreturi = 1/*cristy: daca folosesc RIA, obligatoriu cu tabela de preturi. */
			, @DiscGrupeContr = (
			CASE WHEN tip_parametru = 'GE'
					AND parametru = 'CNTRPG' THEN convert(INT, val_logica) ELSE @DiscGrupeContr END
			)
	FROM par WHERE Tip_parametru='GE' AND Parametru IN ('SUBPRO','PRETURI','CNTRPG')

	/*Daca exista comanda de livrare se ia pretul de acolo ( tabelele con si pozcon )*/
	IF @ComandaLivrare <> ''
		SET @TabelaPreturi = 0

	SELECT @AnulareDiscount = 0, @PretLuatInValuta = 0

	IF (
			@Pret IS NULL
			OR @Discount IS NULL
			)
	BEGIN
		SET @GrupaNom = isnull((
					SELECT max(grupa)
					FROM nomencl
					WHERE @DiscGrupeContr = 1
						AND cod = @Cod
					), '')

		SELECT TOP 1 @PretLuatInValuta = (
				CASE WHEN @Pret IS NULL
						AND p.pret > 0
						AND c.valuta <> '' THEN 1 ELSE @PretLuatInValuta END
				), @Pret = (
				CASE WHEN @Pret IS NULL
						AND p.pret > 0 THEN p.pret * (
								CASE WHEN @IauPretAmanunt = 1 THEN (1 + convert(FLOAT, p.cota_tva) / 100.00
												) ELSE 1 END
								) ELSE @Pret END
				), @Discount = (
				CASE WHEN @Discount IS NULL
						AND p.discount <> 0 THEN p.discount ELSE @Discount END
				)
		FROM con c
		INNER JOIN pozcon p
			ON p.subunitate = c.subunitate
				AND p.tip = c.tip
				AND p.contract = c.contract
				AND p.tert = c.tert
				AND p.data = c.data
		WHERE c.subunitate = @Sb
			AND c.tert = @Tert
			AND (
				c.tip = 'BF'
				AND c.stare IN ('1', '3')
				AND @Data BETWEEN c.data
					AND c.termen
				OR @ComandaLivrare <> ''
				AND c.tip = 'BK'
				AND c.contract = @ComandaLivrare
				)
			AND (
				c.tip = 'BF'
				AND @DiscGrupeContr = 1
				AND @GrupaNom <> ''
				AND left(p.mod_de_plata, 1) = 'G'
				AND p.cod = @GrupaNom
				OR (
					c.tip = 'BK'
					OR rtrim(left(p.mod_de_plata, 1)) = ''
					)
				AND p.cod = @Cod
				)
		ORDER BY (
				CASE WHEN c.tip = 'BK'
						OR rtrim(left(p.mod_de_plata, 1)) = '' THEN 0 ELSE 1 END
				), c.data DESC, c.termen
	END

	/**  
		Daca nu s-a gasit pret in con, pozcon (sau nu a fost cazul) se cauta in tabele de preturi
	**/
	IF (
			@Pret IS NULL
			OR @Discount IS NULL
			)
		AND @TabelaPreturi = 1
	BEGIN
		SELECT @CategPret = sold_ca_beneficiar
		FROM terti
		WHERE @TabelaPreturi = 1
			AND @CategPret = 0
			AND @Tert <> ''
			AND subunitate = @Sb
			AND tert = @Tert

		SET @CategPret = (CASE WHEN isnull(@CategPret, 0) = 0 THEN 1 ELSE @CategPret END)

		SELECT @TipCategorie = 0, @CategorieInValuta = 0, @PretReferinta = 0

		SELECT @TipCategorie = tip_categorie, @CategorieInValuta = in_valuta, @CategReferinta=isnull(categpret.categ_referinta,1)
		FROM categpret
		WHERE categorie = @CategPret

		SELECT TOP 1 @PretReferinta = (CASE WHEN @IauPretAmanunt = 1 THEN pret_cu_amanuntul ELSE pret_vanzare END)
		FROM preturi
		WHERE @TipCategorie = 3
			AND cod_produs = @Cod
			AND UM = @CategReferinta
			AND tip_pret = '1'
			AND @Data BETWEEN data_inferioara
				AND data_superioara
		ORDER BY data_inferioara DESC

		SELECT TOP 1 @PretLuatInValuta = (CASE WHEN @Pret IS NOT NULL THEN @PretLuatInValuta WHEN @TipCategorie = 3 THEN 0 ELSE @CategorieInValuta END
				), @Pret = (
				CASE WHEN @Pret IS NOT NULL THEN @Pret WHEN @TipCategorie = 3 THEN @PretReferinta WHEN @IauPretAmanunt = 1 THEN 
							pret_cu_amanuntul ELSE pret_vanzare END
				), @Discount = (
				CASE WHEN @Discount IS NULL
						AND @TipCategorie = 3 THEN pret_vanzare ELSE @Discount END
				), @AnulareDiscount = (
				CASE WHEN @Pret IS NULL
						AND tip_pret = '9' THEN 1 ELSE @AnulareDiscount END
				)
		FROM preturi p
		WHERE cod_produs = @Cod
			AND p.UM = @CategPret
			AND tip_pret IN ('1', '2','3','9')
			AND ((tip_pret='1' and @Data>=data_inferioara)
				or
				(tip_pret='2' and @Data between data_inferioara and Data_superioara)
				or
				(tip_pret='3' and @Data between data_inferioara and Data_superioara and @ora between Ora_inferioara and Ora_superioara))
		ORDER BY tip_pret DESC, data_inferioara DESC
	END

	/** Daca tot nu s-a gasit un pret (con, pozcon sau tabela preturi) se cauta in pret categoria unu care este pret standard**/
	if isnull(@Pret,0)=0
	begin
		SELECT TOP 1 @PretLuatInValuta = (CASE WHEN @Pret IS NOT NULL THEN @PretLuatInValuta WHEN @TipCategorie = 3 THEN 0 ELSE @CategorieInValuta END
				), @Pret = (
				CASE WHEN @Pret IS NOT NULL THEN @Pret WHEN @TipCategorie = 3 THEN @PretReferinta WHEN @IauPretAmanunt = 1 THEN 
							pret_cu_amanuntul ELSE pret_vanzare END
				), @Discount = (
				CASE WHEN @Discount IS NULL
						AND @TipCategorie = 3 THEN pret_vanzare ELSE @Discount END
				), @AnulareDiscount = (
				CASE WHEN @Pret IS NULL
						AND tip_pret = '9' THEN 1 ELSE @AnulareDiscount END
				)
		FROM preturi p
		WHERE cod_produs = @Cod
			AND p.UM = '1'
			AND tip_pret IN ('1', '2', '9')
			AND @Data BETWEEN data_inferioara
				AND data_superioara
			AND (
				tip_pret <> '2'
				OR data_superioara <= '12/31/2998'
				)
		ORDER BY (CASE WHEN tip_pret = '9' THEN 0 ELSE 1 END),
			(
				CASE WHEN @Pret IS NOT NULL THEN @Pret WHEN @TipCategorie = 3 THEN @PretReferinta WHEN @IauPretAmanunt = 1 THEN 
							pret_cu_amanuntul ELSE pret_vanzare END
				), tip_pret DESC, data_inferioara DESC, data_superioara
	end
	/** Daca tot nu s-a gasit un pret (con, pozcon sau tabela preturi) se cauta in nomenclator **/
	IF @Pret IS NULL
		AND @TabelaPreturi = 0
	BEGIN
		SELECT @Pret = (CASE WHEN @IauPretAmanunt = 1 THEN pret_cu_amanuntul ELSE pret_vanzare END), 
			@PretLuatInValuta = 0
		FROM nomencl
		WHERE cod = @Cod
	END

	IF @Discount IS NULL
	BEGIN
		SELECT @Discount = (
				CASE WHEN terti.disccount_acordat <> 0 THEN terti.disccount_acordat WHEN isnull(gterti.discount_acordat, 0) <> 0 
						THEN gterti.discount_acordat ELSE @Discount END
				)
		FROM terti
		LEFT JOIN gterti
			ON terti.grupa = gterti.grupa
		WHERE terti.subunitate = @Sb
			AND terti.tert = @Tert
	END

	SELECT @Discount = (CASE WHEN @AnulareDiscount = 1 THEN 0 ELSE isnull(@Discount, 0) END), @Pret = isnull(@Pret, 0)

	IF @PretLuatInValuta <> @DocumentInValuta
	BEGIN
		DECLARE @Curs FLOAT, @valuta VARCHAR(3)

		SELECT TOP 1 @Curs = curs, @valuta = nomencl.Valuta
		FROM curs, nomencl
		WHERE nomencl.cod = @Cod
			AND curs.valuta = nomencl.valuta
			AND curs.data <= @Data
		ORDER BY curs.data DESC

		IF (
				@valuta = 'RON'
				OR isnull(@valuta, '') = ''
				) --and @curs=0
			SET @curs = 1
		SET @Pret = round(convert(DECIMAL(15, 5), (CASE WHEN isnull(@Curs, 0) = 0 THEN 0 WHEN @PretLuatInValuta = 1 THEN @Pret * @Curs ELSE @Pret / @Curs END
						)), 5)
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wIaPretDiscount)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
