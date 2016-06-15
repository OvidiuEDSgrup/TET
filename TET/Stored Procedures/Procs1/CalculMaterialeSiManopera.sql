
CREATE PROCEDURE CalculMaterialeSiManopera @sesiune VARCHAR(50), @parXML XML
OUTPUT AS

begin try
	IF EXISTS (SELECT 1 FROM sysobjects WHERE NAME = 'CalculMaterialeSiManoperaSP' AND type = 'P')
	BEGIN
		EXEC CalculMaterialeSiManoperaSP @sesiune , @parXML OUTPUT
		RETURN
	END

	DECLARE @calculat INT, @nivel INT, @idAntec INT, @tert varchar(20)

	select
		@calculat = @parXML.value('(/*/@calculat)[1]', 'int'),
		@nivel = @parXML.value('(/*/@nivel)[1]', 'int'),
		@idAntec = NULLIF(@parXML.value('(/*/@id)[1]', 'int'),''),
		@tert = @parXML.value('(/*/detalii/*/@tert)[1]', 'int')

	IF @idAntec IS NULL --facem calculul din tabela de tehnologii
	begin
		IF OBJECT_ID('tempdb..#temp_calcul') IS NOT NULL
			drop table #temp_calcul

		IF OBJECT_ID('tempdb..#tmp') IS NOT NULL
			drop table #tmp

		select
			cod
		into #tmp
		from anteclcpeCoduri where nivel=@nivel

		;with tmptehn(cod_tehnologie,cod, tip, cantitate, pret, id, nivel)
		as
		(
			select
				m.cod, p.cod,p.tip,convert(float, 1), p.pret,p.id,0
			from tehnologii t
			join #tmp m on t.cod=m.cod
			JOIN pozTehnologii p on p.cod=t.cod and p.tip='T'

			UNION ALL

			select
				t.cod_tehnologie, p.cod, p.tip, t.cantitate*p.cantitate, p.pret,(case when p.tip='R' then (select id from pozTehnologii where tip='T' and cod=p.cod)  else p.id end), t.nivel+1
			from  PozTehnologii p 
			JOIN tmptehn t on p.idp=t.id
	

		)
		select 
			pt.cod_tehnologie, pt.cod,pt.cantitate, pt.tip			
			--SUM(CASE WHEN pt.tip = 'M' THEN ISNULL(pt.cantitate * n.Pret_stoc, 0) ELSE 0 END) AS pretmat, SUM(CASE WHEN pt.tip = 'O' THEN ISNULL(pt.cantitate * c.tarif, 0) ELSE 0 END) AS pretman
		into #temp_calcul
		from tmptehn pt
		
		IF OBJECT_ID('tempdb..#preturi') IS NOT NULL
			drop table #preturi

		create table #preturi (cod varchar(20), nestlevel int)	
		exec CreazaDiezPreturi

		insert into #preturi(cod,nestlevel)
		select distinct cod,@@nestlevel
		from #temp_calcul where tip='M'
				
		exec wIaPreturiAntecalcul @sesiune=@sesiune, @parXML=@parXML

		select
			pt.cod_tehnologie cod, SUM(CASE WHEN pt.tip = 'M' THEN ISNULL(pt.cantitate * p.pret_vanzare, 0) ELSE 0 END) AS pretmat, SUM(CASE WHEN pt.tip = 'O' THEN ISNULL(pt.cantitate * c.tarif, 0) ELSE 0 END) AS pretman
		into #temp_calcul_cen
		from #temp_calcul pt
		LEFT OUTER JOIN nomencl n ON pt.tip = 'M'
			AND pt.cod = n.cod
		LEFT JOIN #preturi p on pt.cod=p.cod and pt.tip='M'
		LEFT OUTER JOIN catop c ON pt.tip = 'O'
			AND pt.cod = c.Cod
		group by pt.cod_tehnologie


		UPDATE anteclcpeCoduri
		SET Mat = preturi.pretmat, Man = preturi.pretman
		FROM anteclcpeCoduri, (

				select cod, pretman, pretmat
				from #temp_calcul_cen
				) preturi
		WHERE anteclcpeCoduri.cod = preturi.cod
			AND anteclcpeCoduri.nivel = @nivel

	end
	ELSE --facem calculul din tabela de antecalculatii
	BEGIN
		UPDATE anteclcpeCoduri
		SET Mat = preturi.pretmat, Man = preturi.pretman
		FROM anteclcpeCoduri, (
				SELECT a.cod, SUM(CASE WHEN pt.tip = 'M' THEN ISNULL(pt.cantitate * pt.pret, 0) ELSE 0 END) AS pretmat, SUM(CASE WHEN pt.tip = 
								'O' THEN ISNULL(pt.cantitate * pt.pret, 0) ELSE 0 END) AS pretman
				FROM dbo.Antecalculatii a
				INNER JOIN dbo.pozAntecalculatii pt ON pt.parinteTop = a.idPoz
				LEFT OUTER JOIN nomencl n ON pt.tip = 'M'
					AND pt.cod = n.cod
				LEFT OUTER JOIN catop c ON pt.tip = 'O'
					AND pt.cod = c.Cod
				WHERE a.idAntec = @idAntec
				GROUP BY a.cod
				) preturi
		WHERE anteclcpeCoduri.cod = preturi.cod
	END


	SET @calculat = @@ROWCOUNT
	set @parXML.modify('delete (/*/@*[local-name()=("nivel", "calculat","id")])')
	SET @parXML.modify('insert attribute calculat {sql:variable("@calculat")} into (/*)[1]')
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
