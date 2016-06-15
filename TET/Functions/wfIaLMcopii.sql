
--Functia este folosita de procedura wIaLocm pentru a genera locurile de munca ierarhic
CREATE FUNCTION wfIaLMcopii (@parXML XML, @codParinte VARCHAR(20))
RETURNS XML

BEGIN
		IF EXISTS (	SELECT 1 FROM sysobjects WHERE NAME = 'wfIaLMcopiiSP' AND type = 'FN')
			RETURN (SELECT dbo.wfIaLMcopiiSP(@parXML, @codParinte))

	DECLARE @subunitate VARCHAR(9), @filtruLM VARCHAR(9), @filtruDenumire VARCHAR(30), @filtruInchCont varchar(20),
		@filtruExpandare varchar(2), @_expandat int

	SELECT @subunitate = val_alfanumerica
	FROM par
	WHERE tip_parametru = 'GE'
		AND parametru = 'SUBPRO'

	SET @filtruLM = @parXML.value('(/row/@lm)[1]', 'varchar(9)')
	SET @filtruDenumire = @parXML.value('(/row/@denlm)[1]', 'varchar(30)')
	SET @filtruInchCont = @parXML.value('(/row/@inchidereConturi)[1]', 'varchar(2)')
	SET @filtruExpandare = @parXML.value('(/row/@f_expandare)[1]', 'varchar(2)')

	/** Daca nu se completeaza filtrul Expandare, sa ramana macheta desfasurata. */
	SELECT @_expandat = (CASE WHEN @filtruExpandare IS NULL OR ISNUMERIC(@filtruExpandare) <> 1 THEN 0 ELSE @filtruExpandare END)
	SELECT @filtruInchCont = (CASE WHEN @filtruInchCont = 'da' THEN '1' WHEN @filtruInchCont = 'nu' THEN '' ELSE NULL END)

	RETURN (
			SELECT rtrim(lm.cod) AS lm, rtrim(lm.denumire) AS denlm, lm.nivel, rtrim(lm.Cod_parinte) AS parinte, rtrim(isnull(lmp.denumire, '')) AS denparinte, 
					isnull(s.tipul_comenzii, '') AS tipcomanda, rtrim(dbo.denTipComanda(s.tipul_comenzii)) AS dentipcomanda, 
					rtrim(left(isnull(s.comanda, ''), 20)) AS comanda, rtrim(isnull(c.descriere, '')) AS dencomanda, 
					rtrim(isnull(s.marca, '')) AS centru, rtrim(substring(isnull(s.comanda, ''), 21, 40)) AS dencentru, 
					rtrim(isnull(pd.Valoare, '')) AS id_domeniu, rtrim(isnull(d.Denumire, '')) AS dendomeniu, 
					rtrim(isnull(po.Valoare, '')) AS ordinestat, rtrim(isnull(cf.Valoare, '')) AS codfiscal,
					(CASE WHEN GETDATE() BETWEEN lm.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
						AND lm.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime') THEN '#808080' END) AS culoare, 
					lm.detalii as detalii, dbo.wfIaLMcopii(@parXML, lm.Cod),
					(CASE WHEN ic.Valoare = '1' THEN 'Da' ELSE 'Nu' END) AS inchidereConturi, --> camp in grid (Inchidere conturi)
					(CASE WHEN ic.Valoare = '1' THEN 1 ELSE 0 END) AS lminchcont, --> form CheckBox (Inchidere conturi)
					(CASE WHEN @_expandat = 0 THEN 'da' WHEN @_expandat > lm.Nivel THEN 'da' ELSE 'nu' END) AS _expandat
			FROM lm lm
			LEFT JOIN lm lmp
				ON lmp.cod = lm.cod_parinte
			LEFT JOIN speciflm s
				ON s.loc_de_munca = lm.cod
			LEFT JOIN comenzi c
				ON c.subunitate = @subunitate AND c.comanda = isnull(s.comanda, '')
			LEFT JOIN proprietati pd
				ON pd.Tip = 'LM' AND pd.Cod = lm.Cod AND pd.Cod_proprietate = 'DOMENIU' AND pd.Valoare <> ''
			LEFT JOIN RU_domenii d ON d.ID_domeniu = pd.Valoare
			LEFT JOIN proprietati po
				ON po.Tip = 'LM' AND po.Cod = lm.Cod AND po.Cod_proprietate = 'ORDINESTAT' AND po.Valoare <> ''
			LEFT JOIN proprietati cf
				ON cf.Tip = 'LM' AND cf.Cod = lm.Cod AND cf.Cod_proprietate = 'CODFISCAL' AND cf.Valoare <> ''
			LEFT JOIN proprietati ic
				ON ic.Tip = 'LM' AND ic.Cod = lm.Cod AND ic.Cod_proprietate = 'LMINCHCONT'
			WHERE lm.Cod_parinte = @codParinte
				AND (
					(
						@filtruLM IS NULL
						OR lm.cod LIKE rtrim(@filtruLM) + '%'
						)
					AND (
						@filtruDenumire IS NULL
						OR lm.denumire LIKE '%' + @filtruDenumire + '%'
						)
					AND (
						@filtruInchCont IS NULL
						OR ic.Valoare = @filtruInchCont
						OR ISNULL(ic.Valoare, '') = @filtruInchCont
						)
					OR dbo.wfIaLMcopii(@parXML, lm.Cod) IS NOT NULL
					)
			--(e director si are copiii)
			FOR XML raw, type
			)
END
