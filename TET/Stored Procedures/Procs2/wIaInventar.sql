
CREATE PROCEDURE wIaInventar @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@subunitate VARCHAR(9), @tip varchar(20), @f_gestiune VARCHAR(9), @f_dengestiune VARCHAR(20), @datajos DATETIME, @datasus DATETIME, 
		@utilizator VARCHAR(20), @f_tip VARCHAR(20), @f_stare VARCHAR(10), @idInventar INT, @are_filtrugest bit, @f_locmunca varchar(100)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	SET @tip = @parXml.value('(/row/@tip)[1]', 'varchar(20)')
	SET @f_tip = '%' + @parXml.value('(/row/@f_tipinventar)[1]', 'varchar(20)') + '%'
	SET @datajos = isnull(@parXml.value('(/row/@datajos)[1]', 'datetime'), '1900-01-01')
	SET @datasus = isnull(@parXml.value('(/row/@datasus)[1]', 'datetime'), '2900-01-01')
	SET @f_gestiune = '%' + @parXml.value('(/row/@f_gestiune)[1]', 'varchar(20)') + '%'
	SET @f_dengestiune = '%' + @parXml.value('(/row/@f_dengestiune)[1]', 'varchar(20)') + '%'
	SET @f_stare = '%' + @parXml.value('(/row/@f_stare)[1]', 'varchar(10)') + '%'
	SET @idInventar = @parXml.value('(/row/@idInventar)[1]', 'int')
	SET @f_locmunca = @parXML.value('(/row/@f_locmunca)[1]', 'varchar(100)')

	declare @GestiuniUser table(valoare varchar(20))	
	insert @GestiuniUser(valoare)
	select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>'' 

	IF EXISTS (select 1 from @GestiuniUser)
		select @are_filtrugest=1

	SELECT top 100 
		rtrim(ai.tip) AS tipinventar, 
		ai.idInventar AS idInventar, 
		(CASE ai.tip WHEN 'G' THEN 'Gestiune' WHEN 'L' THEN 'Loc de munca' WHEN 'M' THEN 'Marca' END) AS dentipinventar, 
		convert(VARCHAR(10), ai.data, 101) data, 
		rtrim(ai.gestiune) AS gestiune, 
		(CASE ai.tip WHEN 'G' THEN rtrim(g.Denumire_gestiune) WHEN 'L' THEN rtrim(l.denumire) WHEN 'M' THEN rtrim(p.nume) END) AS dengestiune, 
		ai.stare AS stare, (CASE ai.stare WHEN 0 THEN 'In curs' WHEN 1 THEN 'Blocat temporar' ELSE 'Rezolvat' END) AS 
		denstare, ISNULL(poz.nr, 0) AS pozitii, ai.grupa as grupa, rtrim(gr.Denumire) as dengrupa,
		(CASE WHEN @tip = 'ID' THEN g.detalii.value('(/row/@lm)[1]', 'varchar(20)') ELSE RTRIM(p.Loc_de_munca) END) AS lm,
		(CASE WHEN @tip = 'ID' THEN g.detalii.value('(/row/@denlm)[1]', 'varchar(150)') ELSE RTRIM(lm.Denumire) END) AS denlm,
		(CASE ai.stare WHEN 0 THEN '#006633' WHEN 1 THEN '#FF0000' ELSE '#808080' END) as culoare , ai.locatie locatie
	FROM AntetInventar ai
	left outer join @GestiuniUser gu on gu.valoare=ai.gestiune and ai.tip='G'
	LEFT JOIN (
		SELECT idInventar, COUNT(1) nr
		FROM PozInventar
		GROUP BY idInventar
		) poz
		ON poz.idInventar = ai.idInventar
	LEFT JOIN gestiuni g
		ON g.Subunitate = @subunitate
			AND ai.gestiune = g.cod_gestiune
			AND ai.tip = 'G'
	LEFT JOIN personal p
		ON p.Marca = ai.Gestiune
			AND ai.tip = 'M'
	LEFT JOIN lm l
		ON l.Cod = ai.gestiune
			AND ai.tip = 'L'
	LEFT JOIN lm
		ON lm.Cod = p.Loc_de_munca
	LEFT JOIN grupe gr
		ON gr.Grupa = ai.grupa
			
	WHERE 
		(@tip='ID' and ai.tip='G' or @tip='IF' and ai.tip<>'G')
		and (@tip<>'ID' or ISNULL(@are_filtrugest,0)=0 OR gu.valoare IS NOT NULL)
		and (ai.gestiune LIKE @f_gestiune OR @f_gestiune IS NULL)
		AND ((@f_dengestiune IS NULL OR (ai.tip = 'G' AND g.Denumire_gestiune LIKE @f_dengestiune) OR (ai.tip = 'L'	AND l.Denumire LIKE @f_dengestiune)	OR (ai.tip = 'M' AND p.Nume LIKE @f_dengestiune)))
		AND ((CASE ai.stare WHEN 0 THEN 'In curs' WHEN 1 THEN 'Blocat temporar' ELSE 'Rezolvat' END) LIKE @f_stare OR @f_stare IS NULL)
		AND ((CASE ai.tip WHEN 'G' THEN 'Gestiune' WHEN 'L' THEN 'Loc de munca' WHEN 'M' THEN 'Marca' END) LIKE @f_tip OR @f_tip IS NULL)
		AND ai.data BETWEEN @datajos AND @datasus
		AND (@idInventar IS NULL OR ai.idInventar = @idInventar)
		and (ai.tip<>'M' or dbo.f_areLMFiltru(@utilizator)=0 or exists(select (1) from LMFiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
		AND (@f_locmunca IS NULL OR (CASE WHEN @tip = 'ID' THEN g.detalii.value('(/row/@lm)[1]', 'varchar(20)') ELSE p.Loc_de_munca END) LIKE '%' + @f_locmunca + '%'
			OR (CASE WHEN @tip = 'ID' THEN g.detalii.value('(/row/@denlm)[1]', 'varchar(150)') ELSE lm.Denumire END) LIKE '%' + @f_locmunca + '%')
	ORDER BY ai.data
	FOR XML raw, root('Date')
