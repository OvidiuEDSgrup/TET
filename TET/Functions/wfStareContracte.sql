
CREATE FUNCTION wfStareContracte (@sesiune VARCHAR(50), @parXML XML)
RETURNS @stareContracte TABLE (idContract INT, stare INT, denStare VARCHAR(50), culoare VARCHAR(50), modificabil BIT)

BEGIN
	DECLARE @f_numar VARCHAR(20), @f_gestiune VARCHAR(20), @f_gestiune_primitoare VARCHAR(20), @f_tert VARCHAR(20), @f_lm VARCHAR(
			20), @f_datajos DATETIME, @f_datasus DATETIME, @idContract INT, @tip VARCHAR(2)

	SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @f_numar = '%' + @parXML.value('(/*/@f_numar)[1]', 'varchar(20)') + '%'
	SET @f_gestiune = '%' + @parXML.value('(/*/@f_gestiune)[1]', 'varchar(20)') + '%'
	SET @f_gestiune_primitoare = '%' + @parXML.value('(/*/@f_gestiune_primitoare)[1]', 'varchar(20)') + '%'
	SET @f_tert = '%' + @parXML.value('(/*/@f_tert)[1]', 'varchar(20)') + '%'
	SET @f_lm = '%' + @parXML.value('(/*/@f_lm)[1]', 'varchar(20)') + '%'
	SET @f_datajos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'), '01/01/1901')
	SET @f_datasus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'), '01/01/2901')
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')

	INSERT INTO @stareContracte (idContract, stare, denStare, culoare, modificabil)
	SELECT ct.idContract, stari.stare, st.denumire, st.culoare, st.modificabil
	FROM Contracte ct
	INNER JOIN (
		SELECT idContract, stare, rank() OVER (
				PARTITION BY idContract ORDER BY data DESC
				) rk
		FROM JurnalContracte
		) stari
		ON ct.idContract = stari.idContract
			AND stari.rk = 1
	INNER JOIN StariContracte st
		ON st.tipContract = @tip
			AND stari.stare = st.stare
	WHERE (
			@idContract IS NULL
			OR ct.idContract = @idContract
			)
		AND (
			@f_numar IS NULL
			OR ct.numar LIKE @f_numar
			)
		AND (
			@f_gestiune IS NULL
			OR ct.gestiune LIKE @f_gestiune
			)
		AND (
			@f_gestiune_primitoare IS NULL
			OR ct.gestiune_primitoare LIKE @f_gestiune_primitoare
			)
		AND (
			@f_tert IS NULL
			OR ct.tert LIKE @f_tert
			)
		AND (
			@f_lm IS NULL
			OR ct.loc_de_munca LIKE @f_lm
			)
		AND ct.data BETWEEN @f_datajos
			AND @f_datasus
		AND (
			ct.tip = @tip
			OR @tip IS NULL
			)

	RETURN
END
