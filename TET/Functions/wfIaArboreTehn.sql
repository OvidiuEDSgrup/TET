
CREATE FUNCTION wfIaArboreTehn (@id INT, @cantitate FLOAT = 0,@sesiune varchar(50)=null)
RETURNS XML
AS
BEGIN
	declare 
		@utilizator varchar(200)
	select  @utilizator = dbo.fIaUtilizator(@sesiune)

	IF EXISTS (SELECT * FROM sysobjects	WHERE NAME = 'wfIaArboreTehnSP'	AND type = 'FN')
	BEGIN
		RETURN (SELECT dbo.wfIaArboreTehnSP(@id, @cantitate,@sesiune))
	END

	DECLARE 
		@tipPozTehnologie VARCHAR(1), @idt INT, @cod VARCHAR(20), @tipNomencl varchar(1)


	/*
		Daca se lucreaza cu semifabricate sau repere (care au o tehnologie proprie) pt. a o afisa in grid trebuie sa-i cautam ID-ul
		Regula de mai jos se aplica: 
			- la semifabricate vom cauta in tehnologii dupa codul de nomenclator al articolului curent
			- la repere vom cauta in tehnologii dupa codul tehnologieii intrucat reperele nu au asociat cod de nomencl
	**/
	SELECT 
		@tipPozTehnologie = tip, @cod = cod
	FROM pozTehnologii p
	WHERE id = @id

	IF @tipPozTehnologie IN ('M','R','F') and EXISTS (SELECT 1	FROM tehnologii	WHERE (codNomencl = @cod and tip='P') OR (cod=@cod and tip in('R','F')))
	BEGIN
		SELECT TOP 1 
			@id = pt.id
		FROM tehnologii t
		JOIN PozTehnologii pt on t.cod=pt.cod and pt.tip='T'
		WHERE  (t.codNomencl = @cod and t.tip='P') OR (t.cod=@cod and t.tip in ('R','F'))
	END

	RETURN 
	(
		SELECT 
			(CASE WHEN p.tip = 'O' THEN 'Operatie' WHEN p.tip = 'R' THEN 'Reper' WHEN (p.tip = 'M' AND p2.id is not null) THEN 'Semifabricat' ELSE 'Material' END) AS _grupare, 
			(CASE WHEN p.tip ='M' THEN rtrim(n.denumire) WHEN p.tip = 'O' THEN rtrim(c.Denumire) WHEN p.tip IN ('R','F') THEN RTRIM(isnull(t.denumire, p.detalii.value('(/row/@denumire)[1]', 'varchar(20)'))) END) AS denumire,
			(CASE WHEN p.tip IN ('M', 'Z') THEN rtrim(n.um) WHEN p.tip = 'O' THEN rtrim(c.um) else 'BUC' END) AS um, 
			(CASE WHEN p.tip = 'R' THEN 'RS' WHEN (p.tip = 'M' AND p2.id is not null) THEN 'SA' WHEN (p.tip = 'M' AND p2.id is null) then 'MT' WHEN p.tip = 'O' THEN 'OP' ELSE 'TT' END) AS subtip, 
			((CASE WHEN p.tip IN ('M', 'Z') THEN rtrim(n.denumire) WHEN p.tip = 'O' THEN rtrim(c.Denumire) ELSE '' END) + ' (' + rtrim(p.cod) + ')') AS denumireCod, 
			(CASE WHEN p.tip NOT IN ('R', 'M','F') THEN p.id WHEN (p.tip IN ('R', 'M','F') AND p2.id IS NOT NULL) THEN p2.id ELSE p.id END) AS id,
			(CASE WHEN @cantitate > 0 THEN CONVERT(DECIMAL(16, 6), p.cantitate * @cantitate) ELSE convert(DECIMAL(16, 6), p.cantitate) END) AS cantitate,
			(CASE WHEN (@cantitate > 0) THEN convert(XML, dbo.wfIaArboreTehn(p.id, p.cantitate * @cantitate,@sesiune)) ELSE convert(XML, dbo.wfIaArboreTehn(p.id, DEFAULT,@sesiune)) END),
			p.id AS idReal, p.idp AS idp, p.parinteTop AS parinteTop, isnull(convert(DECIMAL(10, 2), p.ordine_o), 0) AS ordine, rtrim(p.cod) AS cod, 
			p.idp AS idParinte, ISNULL(convert(DECIMAL(16, 6), p.cantitate_i), 0) AS cant_i, rtrim(p.resursa) AS resursa, CONVERT(DECIMAL(12, 3), p.pret) AS pret,
			p.tip AS tip, rtrim(r.descriere) AS denresursa,(case when p.detalii IS not null then p.detalii end) detalii,
			(case when nexp.id is not null then 'Da' else null end) as _expandat
		FROM pozTehnologii p
		LEFT JOIN poztehnologii p2 ON p2.tip = 'T'AND p2.idp IS NULL AND p.cod = p2.cod 
		LEFT JOIN tehnologii t ON t.cod = p.cod
		LEFT JOIN nomencl n ON n.Cod = p.cod
		LEFT JOIN catop c ON c.Cod = p.cod
		LEFT JOIN resurse r ON r.id = p.resursa AND p.tip = 'O' 
		LEFT JOIN NoduriExpandateTehnologii nexp on nexp.ut=@utilizator and nexp.id=p.id
		WHERE p.idp = @id AND p.tip IN ('M','O','R','F')
		ORDER BY 1 DESC, ISNULL(p.ordine_o,0)
		FOR XML raw, type
	)
END
