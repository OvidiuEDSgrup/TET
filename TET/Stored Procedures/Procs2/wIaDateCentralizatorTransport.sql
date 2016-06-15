
CREATE PROCEDURE wIaDateCentralizatorTransport @sesiune VARCHAR(50), @parXML XML
AS
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wIaDateCentralizatorTransportSP')
	BEGIN
		exec wIaDateCentralizatorTransportSP @sesiune=@sesiune, @parXML=@parXML OUTPUT

		IF @parXML IS NULL
			RETURN
	END

	declare
		@f_articol varchar(200), @f_tert varchar(200), @f_comanda varchar(200), @f_gestiune_stoc varchar(100),  @f_gestiune varchar(20), @f_grupare varchar(200), 
		@f_nivel int, @datajos datetime, @datasus datetime, @date xml, @lista_gestiuni bit,  @utilizator varchar(100), @gestiune_rez varchar(20), 
		@stare_preg varchar(10), @stare_fact varchar(10), @culoare_preg varchar(20), @culoare_fact varchar(20), @f_lm varchar(100)

	select
		@datajos=ISNULL(@parXML.value('(/*/@datajos)[1]','datetime'), DATEADD(YEAR,-50,GETDATE())),
		@datasus=ISNULL(@parXML.value('(/*/@datasus)[1]','datetime'),DATEADD(YEAR,50,GETDATE())),

		@f_articol='%'+ISNULL(@parXML.value('(/*/@f_articol)[1]','varchar(200)'),'%')+'%',
		@f_comanda='%'+ISNULL(@parXML.value('(/*/@f_comanda)[1]','varchar(200)'),'%')+'%',
		@f_tert='%'+ISNULL(@parXML.value('(/*/@f_tert)[1]','varchar(20)'),'%')+'%',
		@f_nivel = ISNULL(NULLIF(@parXML.value('(/*/@f_nivel)[1]','int'),0),0),
		@f_gestiune = '%'+ISNULL(@parXML.value('(/*/@f_gestiune)[1]','varchar(200)'),'%')+'%', 
		@f_gestiune_stoc = '%'+ISNULL(@parXML.value('(/*/@f_gestiune_stoc)[1]','varchar(200)'),'%')+'%', 
		@f_grupare = ISNULL(NULLIF(@parXML.value('(/*/@f_grupare)[1]','varchar(1)'),''),'1'),
		@f_lm = '%'+ISNULL(@parXML.value('(/*/@f_lm)[1]','varchar(200)'),'%')+'%'

	if replace(@f_articol, '%', '')=''
		set @f_articol=null
	if replace(@f_comanda, '%', '')=''
		set @f_comanda=null
	if replace(@f_tert, '%', '')=''
		set @f_tert=null		
	if replace(@f_gestiune, '%', '')=''
		set @f_gestiune=null		
	if replace(@f_gestiune_stoc, '%', '')=''
		set @f_gestiune_stoc=null	
	if @f_grupare not in ('N','P','T')	
		set @f_grupare = null
		
	select top 1 @stare_preg = convert(varchar(10), stare ), @culoare_preg = culoare from StariContracte where tipContract='CL' and modificabil=0
	select top 1 @stare_fact = convert(varchar(10),  stare ), @culoare_fact = culoare from StariContracte where tipContract='CL' and facturabil=1
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	exec luare_date_par 'UC', 'REZSTOCBK', 0, 0, @gestiune_rez OUTPUT

	declare @GestiuniUser table(gestiune varchar(20))
	insert  into @GestiuniUser(gestiune)
	select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTBK' and Valoare<>''

	select @lista_gestiuni=0
	if exists (select * from @GestiuniUser)
		set @lista_gestiuni=1

	/* Daca nu avem date aici facem calculul	*/	
	IF NOT EXISTS (select 1 from tmpArticoleCentralizatorTransport)
	BEGIN
		IF OBJECT_ID('tempdb..#de_transportat') IS NOT NULL
				drop table #de_transportat
	
			select
				c.idContract idContract, MAX(st.stare) stare, pc.idPozContract,isnull(sum(pc.cantitate),0) cantitate_comanda, convert(float, 0.0) cantitate_transport
			into #filtr
			from Contracte c 
			CROSS APPLY 
			(
				select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.transportabil, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=c.tip and j.idContract=c.idContract order by j.data desc
			) st
		JOIN PozContracte pc on c.idContract=pc.idContract and c.tip='CL'
		where ISNULL(st.transportabil,0)=1 and ISNULL(st.inchisa,0)=0
		group BY c.idContract,pc.idPozContract


		update f
			set cantitate_transport = trn.cantitate
		from #filtr f
		JOIN (
			select 
				lc.idPozContractCorespondent idPozContract, SUM(ptr.cantitate) cantitate
			from LegaturiContracte lc 
			INNER JOIN PozContracte ptr on ptr.idPozContract=lc.idPozContract
			INNER JOIN Contracte ctran ON ctran.idContract=ptr.idContract and ctran.tip='CT'
			CROSS APPLY
			(
				select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.transportabil, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=ctran.tip and j.idContract=ctran.idContract order by j.data desc
			) c		
			group by lc.idPozContractCorespondent
		) trn on trn.idPozContract=f.idPozContract


		delete #filtr where ABS(cantitate_comanda-cantitate_transport)<0.001 
	


		insert into tmpArticoleCentralizatorTransport (idContract, idPozContract, comanda, stare, data, tert, cod, cantitate_comanda, cantitate_transport, datacalcul, greutate, grupare)
		select
			f.idContract, f.idPozContract, c.numar, f.stare, c.data, c.tert, pc.cod, CONVERT(decimal(15,2),f.cantitate_comanda), CONVERT(decimal(15,2),f.cantitate_transport), getdate(), n.Greutate_specifica, 'N'
		from #filtr f		
		JOIN Contracte c on c.idContract=f.idContract
		JOIN PozContracte pc on f.idPozContract=pc.idPozContract
		JOIN terti t on t.tert=c.tert
		JOIN Nomencl n on n.cod=pc.cod		
	
	END

	IF OBJECT_ID('tempdb.dbo.#tmpstoc')	IS NOT NULL
		drop table #tmpstoc
	create table #tmpstoc (gestiune varchar(20), dengestiune varchar(100), cod varchar(20), stoc decimal(15,2))
		
	insert into #tmpstoc (gestiune, dengestiune, cod, stoc)
	select rtrim(s.cod_gestiune),rtrim(g.denumire_gestiune), rtrim(s.cod), sum(s.stoc)
	FROM stocuri s
	JOIN (select cod from tmpArticoleCentralizatorTransport group by cod) coduri on coduri.cod=s.cod	
	JOIN Gestiuni g on g.cod_gestiune=s.Cod_gestiune	
	LEFT JOIN @GestiuniUser gu on gu.gestiune=g.Cod_gestiune
	where (@lista_gestiuni=0 OR gu.gestiune IS NOT NULL) and stoc>0.0 and s.cod_gestiune<>ISNULL(@gestiune_rez,'')
	group by s.cod_gestiune,g.denumire_gestiune, s.cod	
	
	-- Stocul pt. comenzile in pregatire sau transportat este in gestiunea de rezervari deci se exlude la calcul, nu mai trebuie alte calcule
	--update t
	--	set stoc=stoc-c.cantitate
	--from #tmpstoc t
	--JOIN (select gestiune, cod, sum(isnull(cantitate,0)) cantitate from tmpArticoleCentralizatorTransport group by gestiune, cod) c on t.gestiune=c.gestiune and c.cod=t.cod

	delete #tmpstoc where ABS(stoc)<0.01

	IF OBJECT_ID('tempdb.dbo.#grupari') IS NOT NULL
		drop table #grupari
	create table #grupari (grupare varchar(100), denumire varchar(200), filtre bit, utilizator bit, stare bit, ordine int, culoare varchar(10))

	INSERT INTO #grupari (grupare, denumire, filtre, utilizator, stare, ordine, culoare)
	select @stare_preg, 'Comenzi pregatire', 1, 0, 1, 40,@culoare_preg  UNION
	select  @stare_fact, 'Comenzi de transportat', 1, 0, 1, 30, @culoare_fact UNION
	select 'N', 'Comenzi nealocate', 1, 0, 0, 20, '#FF0000' UNION
	select 
		rtrim(id)+convert(varchar(2), t.n), rtrim(nume)+ ' '+convert(varchar(2), t.n), 0, 1, 0, (case when u.id=@utilizator then t.n else 90+t.n end),'' 
	from Utilizatori u JOIN Tally t on t.n<10
					
	update t
		set stare=st.stare
	from tmpArticoleCentralizatorTransport t
	CROSS APPLY 
	(
		select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.transportabil, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract='CL' and j.idContract=t.idContract order by j.data desc
	) st	
		
	update t
		set t.grupare='N'
	from tmpArticoleCentralizatorTransport t
	JOIN #grupari g on t.grupare=g.grupare and g.utilizator<>1			
	
	update t
		set t.grupare=g.grupare
	from tmpArticoleCentralizatorTransport t
	JOIN #grupari g on convert(varchar(10), t.stare)=g.grupare 
	JOIN #grupari gu on gu.grupare=t.grupare and gu.utilizator<>1
		
	update tmpArticoleCentralizatorTransport set cantitate=cantitate_comanda where grupare in (@stare_fact, @stare_preg)

	set @date = 
		(
			select
				MAX(g.denumire) numar,
				MAX(g.denumire) dentert,
				t.grupare grupare,							
				(case when @f_nivel in (1,2) then 'Da' end) _expandat,
				sum(t.cantitate_comanda) cantitate_comanda, 
				sum(t.cantitate_transport) cantitate_transport,
				convert(decimal(15,2), sum(case t.grupare when 'N' then t.cantitate_comanda else ISNULL(t.cantitate,0) end *t.greutate)) greutate_transport,
				g.culoare culoare,
				(
					select
						max(comanda) numar, 
						max(rtrim(te.denumire)) + max(rtrim(ISNULL(NULLIF(it.cont_in_banca2,''),l.oras)))+' ('+max(rtrim(ISNULL(NULLIF(it.descriere,''),''))) +'-'+')' denumire ,
						MAX(c.gestiune) gestiune_comanda,
						MAX(rtrim(g2.denumire_gestiune)) dengestiune_comanda,
						MAX(rtrim(g2.denumire_gestiune)) dengestiune,
						t2.idContract idcontract,
						convert(decimal(15,2), sum(t2.cantitate_comanda)) cantitate_comanda, 
						convert(decimal(15,2), sum(t2.cantitate_transport)) cantitate_transport, 
						convert(decimal(15,2), sum(case t2.grupare when 'N' then t2.cantitate_comanda else ISNULL(t2.cantitate,0) end *t2.greutate)) greutate_transport,
						(case when @f_nivel=2 then 'Da' end) _expandat, 
						t2.grupare grupare,
						(
							select 
								t3.cod,
								rtrim(n.denumire) denumire, 
								t3.idPozContract,  
								t3.idlinie idlinie,
								t3.cod numar, 
								ISNULL(MAX(c.gestiune), pc.detalii.value('(/*/@gestiune)[1]','varchar(20)')) gestiune_comanda,
								RTRIM(ISNULL(MAX(g2.denumire_gestiune), g3.denumire_gestiune)) dengestiune_comanda,
								convert(decimal(15,2),t3.cantitate_comanda) cantitate_comanda, 
								convert(decimal(15,2),t3.cantitate_transport) cantitate_transport, 
								convert(decimal(15,2),(case t3.grupare when 'N' then t3.cantitate_comanda else ISNULL(t3.cantitate,0) end)*t3.greutate) greutate_transport,								
								ts.gestiune gestiune,
								ts.dengestiune dengestiune,
								convert(decimal(15,2),coalesce(ts.stoc,0))-isnull((case when t2.grupare='N' then t9.cantComandaDeasupra else 0 end),0) stoc,
								(case when t3.grupare='N' and isnull(ts.stoc,0)-isnull(t9.cantComandaDeasupra,0) - t3.cantitate_comanda < 0 then '#FF0000' end ) culoare
							from tmpArticoleCentralizatorTransport t3 
							JOIN PozContracte pc on pc.idPozContract=t3.idPozContract							
							JOIN #grupari g on g.grupare=t3.grupare
							JOIN Nomencl n on n.cod=t3.cod								
							LEFT JOIN Gestiuni gc on gc.cod_gestiune=pc.detalii.value('(/*/@gestiune)[1]','varchar(20)')
							LEFT JOIN #tmpstoc ts on ts.cod=t3.cod and t3.grupare='N' and (@f_gestiune_stoc IS NULL or ts.gestiune like @f_gestiune_stoc or ts.dengestiune like @f_gestiune_stoc)
							LEFT JOIN Gestiuni g3 on g3.cod_gestiune=t3.gestiune and t3.grupare='N'							
							outer apply (select sum(cantitate_comanda) as cantComandaDeasupra 
								from tmpArticoleCentralizatorTransport t9 
								JOIN Contracte cs on cs.idContract=t9.idContract
								JOIN lm lms on lms.Cod=cs.loc_de_munca
								where t9.grupare='N' and t3.grupare='N' and t9.cod=t3.cod 
								and (t9.idContract<t3.idContract or t9.idContract=t3.idContract and t9.cantitate_comanda>t3.cantitate_comanda)
								and (NULLIF(@f_lm,'') is null or lms.Denumire like @f_lm)
								) t9 
							where t2.grupare=t3.grupare and t3.idContract=t2.idContract
							order by t3.cantitate_comanda desc
							for xml raw, type
						)
					from tmpArticoleCentralizatorTransport t2					
					JOIN Terti te on te.tert=t2.tert
					JOIN Contracte c on c.idContract=t2.idContract
					JOIN lm on lm.Cod=c.loc_de_munca
					LEFT JOIN InfoTert it on it.identificator=c.punct_livrare and it.identificator<>'' and it.tert=te.tert
					LEFT JOIN Localitati l on l.cod_oras=te.localitate
					LEFT JOIN Gestiuni g2 on g2.cod_gestiune=c.gestiune
					JOIN nomencl n on n.cod=t2.cod
					where t.grupare=t2.grupare and
					(g.filtre=0 or ((t2.comanda like @f_comanda or @f_comanda is null ) and (NULLIF(@f_lm,'') is null or lm.Denumire like @f_lm) and 
					t2.data between @datajos and @datasus and (te.tert like @f_tert OR te.Denumire like @f_tert or @f_tert is null)
						and (t2.cod like @f_articol OR n.Denumire like @f_articol or @f_articol is null) and 
						(@f_gestiune is null or c.gestiune like @f_gestiune or ISNULL(g2.denumire_gestiune,'') like @f_gestiune )))					
					group by t2.idContract,t2.grupare
					order by t2.idContract
					for xml raw, type
				)
			from tmpArticoleCentralizatorTransport t 
			JOIN #grupari g on g.grupare=t.grupare
			where @f_grupare IS NULL OR (@f_grupare='N' and g.grupare='N') OR (@f_grupare='P' and g.grupare=@stare_preg) OR (@f_grupare='T' and g.grupare not in ('N',@stare_preg))
			group by t.grupare, g.filtre, g.ordine, g.culoare
			order by g.ordine
			for xml raw, root('Ierarhie'), type
		) 

	select @date for xml raw('Date')
