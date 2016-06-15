
CREATE PROCEDURE wIaPozTehnologii @sesiune VARCHAR(50), @parXML XML
AS

IF EXISTS (SELECT 1	FROM sysobjects	WHERE [type] = 'P'AND [name] = 'wIaPozTehnologiiSP')
BEGIN
	EXEC wIaPozTehnologiiSP @sesiune = @sesiune, @parXML = @parXML
	RETURN
END

	DECLARE 
		@codt VARCHAR(20), @fltcod VARCHAR(20), @fltdenumire VARCHAR(20), @flttip VARCHAR(20), @doc XML, @add XML, @id INT, @tip VARCHAR(20), 
		@denumire VARCHAR(80),@utilizator varchar(50) , @cautare varchar(500)

	select @codt = ISNULL(@parXML.value('(/row/@cod_tehn)[1]', 'varchar(20)'), ''),
		   @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')
	exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator OUTPUT

	SELECT top 1 
		@tip = (CASE t.tip when 'P' THEN 'Produs' WHEN 'R' THEN 'Reper' WHEN 'S' THEN 'Serviciu' WHEN 'I' THEN 'Interventie' when 'F' then 'Faza' END), 
		@denumire = RTRIM(denumire), @id = p.id, @doc=''
	FROM tehnologii t
	INNER JOIN poztehnologii p ON t.cod = p.cod and t.cod=@codt and p.tip='T'

	SET @doc = 
	(
		SELECT 
			(CASE WHEN p.tip = 'O' THEN 'Operatie' WHEN p.tip = 'R' THEN 'Reper' WHEN (p.tip = 'M' AND p2.id is not null) THEN 'Semifabricat' ELSE 'Material' END) AS _grupare, 
			(CASE WHEN p.tip ='M' THEN rtrim(n.denumire) WHEN p.tip = 'O' THEN rtrim(c.Denumire) WHEN p.tip IN ('R','F') THEN RTRIM(isnull(t.denumire, p.detalii.value('(/row/@denumire)[1]', 'varchar(20)'))) END) AS denumire, 
			(CASE WHEN p.tip IN ('M', 'Z') THEN rtrim(n.um) WHEN p.tip = 'O' THEN rtrim(c.um) else 'BUC' END) AS um,
			(CASE WHEN p.tip NOT IN ('R', 'M','F') THEN p.id WHEN (p.tip IN ('R', 'M','F') AND p2.id IS NOT NULL) THEN p2.id ELSE p.id END) AS id,
			(CASE WHEN p.tip = 'R' THEN 'RS' WHEN (p.tip = 'M' AND p2.id is not null) THEN 'SA' WHEN (p.tip = 'M' AND p2.id is null) then 'MT' WHEN p.tip = 'O' THEN 'OP' ELSE 'TT' END) AS subtip, 
			RTRIM(r.descriere) AS denresursa, p.id AS idReal, p.idp AS idp, p.parinteTop AS parinteTop,  @codt AS cod_tehn,		
			isnull(convert(DECIMAL(10, 6), p.ordine_o), 0) AS ordine, rtrim(p.cod) AS cod, p.idp AS idParinte, convert (DECIMAL(12, 3), p.pret) AS pret, 
			p.tip AS tip, convert(DECIMAL(16, 6), p.cantitate) AS cantitate, ISNULL(convert(DECIMAL(16, 6), p.cantitate_i), 0) AS cant_i,
			rtrim(p.resursa) AS resursa, convert(XML, dbo.wfIaArboreTehn(p.id,DEFAULT,@sesiune)),
			(CASE WHEN p.detalii IS NOT NULL THEN p.detalii END) detalii,(case when nexp.id is not null then 'Da' else null end) as _expandat
		FROM pozTehnologii p
		LEFT JOIN poztehnologii p2 ON p2.tip = 'T' AND p2.idp IS NULL AND p2.cod = p.cod 
		LEFT JOIN tehnologii t ON t.cod = p.cod
		LEFT JOIN nomencl n	ON n.Cod = p.cod
		LEFT JOIN catop c ON c.Cod = p.cod
		LEFT JOIN resurse r	ON r.id = p.resursa AND p.tip = 'O'
		LEFT JOIN NoduriExpandateTehnologii nexp on nexp.ut=@utilizator and nexp.id=p.id
		WHERE p.idp = @id AND p.tip IN ('M','O','R','F') and (isnull(n.Denumire,'') like '%'+@cautare+'%' or p.cod like @cautare+'%')
		ORDER BY 1 DESC, ISNULL(p.ordine_o,0)
		FOR XML raw, root('Pozitii')
	)

		IF @doc IS NOT NULL
			SET @doc.modify('insert (
							attribute _grupare {sql:variable("@tip")},
							attribute cod {sql:variable("@codt")},
							attribute id {sql:variable("@id")},
							attribute denumire {sql:variable("@denumire")},
							attribute _expandat {"Da"}
						) into (/Pozitii)[1]')

		ELSE
			set @doc= (select @tip _grupare, @codt cod, @id id, @denumire denumire, 'Da' _expandat for xml raw('Pozitii'))
	
		SELECT @doc
		FOR XML path('Ierarhie'),root('Date') 

		SELECT '1' AS areDetaliiXml
		FOR XML raw, root('Mesaje')
