
CREATE PROCEDURE wIaAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@fltCod VARCHAR(20), @fltPretJos FLOAT, @fltPretSus FLOAT, @fltDenumire VARCHAR(80), @fltNumarDoc VARCHAR(10), @datajos 
		DATETIME, @datasus DATETIME, @idAntec VARCHAR(10)

	SET @fltCod = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_cod)[1]', 'varchar(20)'), '%'), ' ', '%') + '%'
	SET @fltDenumire = '%' + replace(ISNULL(@parXML.value('(/row/@f_denumire)[1]', 'varchar(20)'), '%'), ' ', '%') + '%'
	SET @fltNumarDoc = '%' + replace(ISNULL(@parXML.value('(/row/@f_numarDoc)[1]', 'varchar(20)'), '%'), ' ', '%') + '%'
	SET @fltPretJos = ISNULL(@parXML.value('(/row/@f_pretJos)[1]', 'float'), 0)
	SET @fltPretSus = ISNULL(@parXML.value('(/row/@f_pretSus)[1]', 'float'), 9999999)
	SET @datajos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '1901-1-1')
	SET @datasus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '2100-1-1')
	SET @idAntec = isnull(@parXML.value('(/row/@idAntec)[1]', 'varchar(10)'), '%')

	SELECT TOP 100 
		RTRIM(a.cod) AS cod, RTRIM(n.denumire) AS denumire, convert(CHAR(10), a.data, 101) AS data, CONVERT(DECIMAL(12, 5), a.
			pret) AS pret, convert(DECIMAL(12, 5), pta.cantitate) AS cantitate, a.numar AS numarDoc, (CASE WHEN isnull(a.valuta, '') = '' THEN 'RON' ELSE RTRIM(a.valuta) END
			) AS valuta, CONVERT(DECIMAL(12, 5), a.curs) AS curs, CONVERT(DECIMAL(12, 5), a.pret / a.curs) AS pretValuta, a.idAntec AS 
		idAntec, idAntec as numar
	FROM antecalculatii a
	INNER JOIN pozAntecalculatii pta ON a.idPoz = pta.id
	INNER JOIN Tehnologii t on t.cod=a.cod
	INNER JOIN nomencl n ON n.Cod = t.codNomencl
	WHERE a.cod LIKE @fltCod
		AND a.idAntec LIKE @idAntec
		AND n.denumire LIKE @fltDenumire
		AND a.numar LIKE @fltNumarDoc
		AND convert(DATE, a.data) BETWEEN @datajos
			AND @datasus
		AND a.pret BETWEEN @fltPretJos
			AND @fltPretSus
	ORDER BY a.data desc, a.numar desc
	FOR XML raw, root('Date')
