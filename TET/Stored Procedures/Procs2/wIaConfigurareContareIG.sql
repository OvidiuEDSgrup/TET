
--***

CREATE PROCEDURE wIaConfigurareContareIG @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @utilizator varchar(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT RTRIM(cc.cont_de_stoc) AS cont_de_stoc, RTRIM(c1.Denumire_cont) AS dencont_de_stoc,
		RTRIM(cc.cont_cheltuieli) AS cont_cheltuieli, RTRIM(c2.Denumire_cont) AS dencont_cheltuieli,
		RTRIM(cc.cont_venituri) AS cont_venituri, RTRIM(c3.Denumire_cont) AS dencont_venituri,
		cc.analiticg, cc.analiticcs, ISNULL(cc.Tip, '') AS tipdoc,
		(CASE WHEN cc.analiticg = 1 THEN 'DA' ELSE 'NU' END) AS den_analiticg, 
		(CASE WHEN cc.analiticcs = 1 THEN 'DA' ELSE 'NU' END) AS den_analiticcs, 
		cc.nrord 
	FROM ConfigurareContareIesiriDinGestiune cc
	LEFT JOIN conturi c1 ON c1.Cont = cc.cont_de_stoc
	LEFT JOIN conturi c2 ON c2.Cont = cc.cont_cheltuieli
	LEFT JOIN conturi c3 ON c3.Cont = cc.cont_venituri
	ORDER BY nrord
	FOR XML RAW, ROOT('Date')

END
