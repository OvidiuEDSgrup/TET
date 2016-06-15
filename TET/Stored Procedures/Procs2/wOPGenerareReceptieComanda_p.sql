
CREATE PROCEDURE wOPGenerareReceptieComanda_p @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @cuRezervari bit, @gestiuneRezervari varchar(20), @lm varchar(20), @tert varchar(20),
		@gestiune varchar(13), @dengestiune varchar(200), @dengestiuneRezervari varchar(1000),
		@dentert varchar(100), @denlm varchar(100), @idContract int, @valuta varchar(10), @curs decimal(17,4),
		@prePopulare bit, @nr_receptie varchar(20), @data_receptie datetime, @factura varchar(50),
		@data_facturii datetime

	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT

	SELECT @denlm = @parXML.value('(/*/@denlm)[1]', 'varchar(100)'),
		@dentert = @parXML.value('(/*/@dentert)[1]','varchar(100)'),
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@dengestiune = @parXML.value('(/*/@dengestiune)[1]', 'varchar(200)'),
		@tert = @parXML.value('(/*/@tert)[1]', 'varchar(100)'),
		@lm = @parXML.value('(/*/@lm)[1]', 'varchar(100)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@valuta = ISNULL(@parXML.value('(/*/@valuta)[1]', 'varchar(10)'), ''),
		@prePopulare = ISNULL(@parXML.value('(/*/@prePopulare)[1]', 'bit'), 0),
		@nr_receptie = NULLIF(@parXML.value('(/*/@nr_receptie)[1]', 'varchar(20)'), ''),
		@data_receptie = ISNULL(@parXML.value('(/*/@data_receptie)[1]', 'datetime'), GETDATE())

	IF @valuta <> '' AND @prePopulare = 0 and exists (select 1 from webconfigmeniu where meniu='PCC')
	BEGIN
		IF EXISTS (SELECT 1 FROM tabelXML WHERE sesiune = @sesiune)
			DELETE FROM tabelXML WHERE sesiune = @sesiune

		SELECT 1 AS inchideFereastra FOR XML RAW, ROOT('Mesaje')

		SELECT 'Populare curs comanda aprov.' AS nume, 'PCC' AS codmeniu, 'O' AS tipmacheta,
			(SELECT @valuta AS valuta, @tert AS tert, @dentert AS dentert,
				@gestiune AS gestiune, @dengestiune AS dengestiune, @lm AS lm,
				@idContract AS idContract, @denlm AS denlm FOR XML RAW, TYPE) AS dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
		
		SELECT @curs = date.value('(/row/@curs)[1]', 'decimal(17,4)'),
			@nr_receptie = date.value('(/row/@nr_receptie)[1]', 'varchar(20)'),
			@data_receptie = date.value('(/row/@data_receptie)[1]', 'datetime')
		FROM tabelXML WHERE sesiune = @sesiune

		DELETE FROM tabelXML WHERE sesiune = @sesiune
	END

	SET @curs = ISNULL(@curs, 1)

	/** Denumirea gestiunii de rezervari **/
	SELECT TOP 1 @dengestiuneRezervari = RTRIM(g.Denumire_gestiune)
	FROM gestiuni g WHERE g.Cod_gestiune = @gestiuneRezervari

	/** Datele de "antet" ale operatiei **/
	SELECT @dengestiuneRezervari AS dengestiuneRezervari, @dengestiune AS dengestiune, @denlm AS denlm, @dentert AS dentert, @tert AS tert, 
		@gestiuneRezervari AS gestiuneRezervari, @gestiune AS gestiune, @lm AS lm, CONVERT(varchar(10), @data_receptie, 101) AS data
	FOR XML RAW, ROOT('Date')

	/** Populam grid-ul editabil cu codurile sparte pe comenzi care vor ajunge in receptie **/
	SELECT 
	(
		SELECT p.cod AS cod, CONVERT(decimal(15,3), dbo.valoare_maxima(p.cantitate - ISNULL(r.cant_receptionata, 0), 0, 0)) AS cantitate,
			CONVERT(decimal(15,5), p.pret) AS pret, rtrim(pc.cod) AS comanda, RTRIM(n.Denumire) AS denumire, p.idPozLansare AS idPozLansare,
			p.idPozContract AS idPozContract, @idContract AS idContract, CONVERT(decimal(15,3), r.cant_receptionata) AS cant_receptionata,
			CONVERT(decimal(15,3), p.cantitate) AS cant_comanda, @curs AS curs, CONVERT(decimal(15,5), p.pret * @curs) AS pret_intrare
		FROM PozContracte p 
		INNER JOIN nomencl n ON n.cod = p.cod
		--calculam cantitatile deja receptionate, si sugeram doar diferenta ramasa
		OUTER APPLY (
			SELECT MAX(pd.cod) AS cod, SUM(pd.cantitate) AS cant_receptionata 
			FROM pozdoc pd
			INNER JOIN legaturicontracte l ON l.idpozdoc = pd.idpozdoc AND p.idpozcontract = l.idpozcontract AND pd.tip = 'RM' 
			GROUP BY l.idpozcontract
		) r
		LEFT JOIN pozLansari poz ON poz.id = p.idPozLansare
		LEFT JOIN pozLansari pc ON pc.id = poz.parinteTop AND pc.tip = 'L'
		WHERE p.idContract = @idContract
		ORDER BY p.cod, pc.cod
		FOR XML RAW, TYPE
	)
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
END
