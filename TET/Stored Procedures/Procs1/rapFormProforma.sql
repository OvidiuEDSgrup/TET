
CREATE PROCEDURE rapFormProforma @sesiune varchar(50), @idContract int
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRY
	if exists (select 1 from sys.sysobjects where name = 'rapFormProformaSP' and type = 'P')
	begin
		exec rapFormProformaSP @sesiune = @sesiune, @idContract = @idContract
		return
	end
	DECLARE
		@utilizator varchar(50), @cota_TVA float, @unitate varchar(200), @cui varchar(100),
		@adresa varchar(200), @sediu varchar(100), @judet varchar(100), @cont varchar(100),
		@banca varchar(100), @subunitate varchar(9), @ordreg varchar(100), @tert varchar(20),
		@tert_extern int, @tva_tert varchar(1), @capital varchar(20), @nrExemplare int = 1

	--EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT @subunitate = rtrim(val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru = 'SUBPRO'
	SELECT @unitate = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	SELECT @cui = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
	SELECT @ordreg = RTRIM(val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru = 'ORDREG'
	SELECT @adresa = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ADRESA'
	SELECT @sediu = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
	SELECT @judet = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
	SELECT @cont = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CONTBC'
	SELECT @banca = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'BANCA'
	SELECT @capital = RTRIM(val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru = 'CAPITALS'

	SELECT @tert = tert FROM contracte WHERE idContract = @idContract
	
	SELECT @tert_extern = tert_extern, @tva_tert = ISNULL(ttva.tip_tva, 'P') 
	FROM terti t 
	OUTER APPLY (SELECT TOP 1 tip_tva FROM TvaPeTerti tv WHERE tv.tert = t.tert AND GETDATE() > tv.dela ORDER BY dela DESC) AS ttva
	WHERE t.tert = @tert AND t.Subunitate = @subunitate

	SELECT
		@unitate AS UNITATE, @cui AS CUI, @adresa AS ADRESA, @sediu AS SEDIU,
		@judet AS JUDET, @cont AS CONT, @banca AS BANCA, @capital AS capital,
		@ordreg AS ordreg,
		RTRIM(c.numar) AS proforma, CONVERT(varchar(10), c.data, 103) AS data,
		RTRIM(c.tert) AS tert, RTRIM(t.Denumire) AS dentert,
		RTRIM(ISNULL(l.oras, t.localitate)) AS localitate_ben,
		RTRIM(it.banca3) AS ordreg_ben,
		RTRIM(t.cod_fiscal) AS codfiscal_ben,
		RTRIM(isnull(j.denumire, t.judet)) AS judet_ben,
		(ISNULL(RTRIM(l.oras), RTRIM(t.localitate)) + ', ' + LTRIM(RTRIM(LEFT(t.adresa, 20)))) AS adresa_ben,
		RTRIM(t.cont_in_banca) AS cont_ben,
		(ISNULL(RTRIM(b.Denumire), RTRIM(t.banca)) + ', ' + RTRIM(b.Filiala)) AS banca_ben,
		CONVERT(decimal(17,5), c.curs) AS curs,

		tal.N AS nr,
		ROW_NUMBER() OVER (PARTITION BY tal.n ORDER BY n.Denumire) as nrcrt,
		RTRIM(pcc.cod) AS cod,
		RTRIM(n.Denumire) AS dencod,
		RTRIM(n.UM) AS um,
		CONVERT(decimal(15,2), pcc.cantitate) AS cantitate,
		CONVERT(decimal(17,5), pcc.pret) AS pret,
		ROUND(pcc.pret * pcc.cantitate, 2) AS valoare_cl,
		ROUND(pc.pret * pc.cantitate, 2) AS valoare_proforma,
		(CASE WHEN @tert_extern = 0 OR (@tert_extern = 1 AND @tva_tert = 'N') THEN (pcc.pret * pcc.cantitate
		* (CASE WHEN ISNULL(c.valuta, '') <> '' THEN c.curs ELSE 1 END) * n.cota_tva / 100) ELSE 0 END) AS tva
	into #proforma
	FROM Contracte c
		INNER JOIN Contracte cc ON cc.idContract = c.idContractCorespondent AND c.tip = 'PR'
		INNER JOIN PozContracte pc ON pc.idContract = c.idContract -- pozitie proforma
		INNER JOIN PozContracte pcc ON pcc.idContract = cc.idContract -- pozitii comanda livrare
		INNER JOIN Tally tal ON tal.N <= @nrExemplare
		LEFT JOIN nomencl n ON n.Cod = pcc.cod
		LEFT JOIN terti t ON t.Subunitate = @subunitate AND t.Tert = c.tert
		LEFT JOIN infotert it ON it.Subunitate = @subunitate AND it.Tert = t.tert AND it.Identificator = ''
		LEFT JOIN localitati l ON t.localitate = l.cod_oras
		LEFT JOIN judete j ON t.judet = j.cod_judet
		LEFT JOIN bancibnr b ON b.Cod = t.Banca
	WHERE c.idContract = @idContract

	--daca pe comanda de livrare se pune tva, atunci trebuie ca si valoarea proformei sa contina tva
	update p set valoare_proforma=round(valoare_proforma+pr.tva,2)
	from #proforma p
		outer apply(select sum(tva) tva
					from #proforma p2) pr

	select * from #proforma
END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
