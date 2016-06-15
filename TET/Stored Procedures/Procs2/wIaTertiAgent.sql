
CREATE PROCEDURE wIaTertiAgent @sesiune VARCHAR(50), @parxml XML
AS
	DECLARE 
		@utilizator VARCHAR(100), @lm VARCHAR(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @lm = isnull(dbo.wfProprietateUtilizator('LOCMUNCA', @utilizator), '')

	SELECT 
		RTRIM(t.tert) AS cod, RTRIM(ISNULL(rtrim(it2.descriere)+'-','')+ t.denumire) AS denumire, 
		ISNULL(RTRIM(it2.Identificator),'') pctliv, isnull(rtrim(t.cod_fiscal), rtrim(t.adresa)) AS info
	FROM terti t
	LEFT JOIN infotert it ON it.subunitate = t.subunitate
		AND it.tert = t.tert
		AND it.identificator = ''
	left join infotert it2 /*puncte livrare*/ 
	on it2.subunitate=t.Subunitate and it2.tert=t.tert and 
		it2.identificator<>''
	WHERE it.loc_munca = @lm
	FOR XML raw, root('Date')
