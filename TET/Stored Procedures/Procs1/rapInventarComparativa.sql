--***
create procedure rapInventarComparativa(@sesiune varchar(50)=null,
		@dData datetime,
		@tipgest varchar(1),	--> tip gestiune: Depozit, Folosinta, (cusTodie)
		@ordonare varchar(1),	--> 'c'=cod, 'd'=denumire
		@grupare_cod_pret bit=0,
		@grupare varchar(1),	--> locm(=1), gestiune; nu functioneaza! (procedura nu aduce locuri de munca)
		@cCod varchar(50)=null, @cGestiune varchar(50)=null, @locm varchar(50)=null,
		@cont varchar(50)=null, 
		@contnom varchar(50)=null, @antetInventar int=null,
		@tippret varchar(1)='s',	--> s,t,v s=pret de stoc, t=f(tip gestiune), v=pret vanzare
		@categpret smallint=null,
		@faraDocumentCorectie int=0, -->Implicit cu documente de corectie
		@locatie varchar(200)=null,
		@standard int=0	--> apel procedura pentru: 0=inventar comparativa, 1=inventar standard, 2=inventar folosinta
		)
as
begin
	set transaction isolation level read uncommitted
	declare @eroare varchar(500), @cGrupa varchar(13), @gestiuneXML varchar(50), @cui varchar(50),
		@ordreg varchar(50), @adresa varchar(200)

	set @eroare=''
	begin try
	
	-->	tratare erori, prelucrari parametri:
		--> exista doua variante ale raportului:  daca exista date in antetInventar se foloseste parametrul 
		-->				@antetInventar,	altfel se lucreaza cu parametri @gestiune, @data, @locm
		declare @variantaNoua bit	--> parametru care semnalizeaza folosirea noilor structuri
		select @variantaNoua=(case when not (exists (select 1 from sys.objects where name='antetinventar') and (select count(1) from antetinventar)>0) then 0 else 1 end)
		select @variantaNoua=(case when @standard=0 then @variantaNoua else 0 end)
		if isnull(@antetInventar,0)=0 and @variantaNoua=1 and @cGestiune is null and @locm is null
			raiserror('Este necesara specificarea unui antet de inventar, gestiune sau loc de munca!',16,1)
		if (@variantaNoua=1 or @standard<>0) and isnull(@antetInventar, 0) <> 0
			select @cGestiune=a.gestiune, @dData=a.data, @cGrupa=grupa from antetInventar a where a.idInventar=@antetInventar
		else if @cGestiune is null and @locm is null
			raiserror('Completati gestiunea!',16,1)

		if (@cGestiune is null and isnull(@antetInventar,0)>0 and @variantaNoua = 0)
			raiserror('Nu s-a gasit inventarul in antet inventar!',16,1)

		--if @standard<2 and (@cGestiune is null) raiserror('Este necesara completarea gestiunii!',16,1)
		--if @standard=2 and (@cGestiune is null) raiserror('Este necesara completarea marcii!',16,1)
		
		if (@tippret<>'s' and @categPret is null and @cGestiune is null)
		raiserror('Pentru tip pret diferit de pret de stoc alegeti o categorie de pret!',16,1)

		/** In cazul in care se selecteaza un antet inventar din depozit, iar tip gestiune = 'Folosinta',
			atunci schimbam tipul ...si reciproc. */
		if isnull(@antetInventar, 0) <> 0 and not exists (select 1 from AntetInventar where idInventar = @antetInventar
			and tip = (case when @tipgest = 'D' then 'G' else 'M' end))
			set @tipgest = (case when @tipgest = 'D' then 'F' else 'D' end)

		declare @subunitate varchar(20), @flt_cCod bit, @flt_contnom bit
		select @subunitate=isnull((select rtrim(val_alfanumerica) from par
							where tip_parametru='GE' and parametru='subpro'),'1'),
				@flt_cCod=(case when @cCod is null then 0 else 1 end),
				@flt_contnom=(case when @contnom is null then 0 else 1 end),
	-->	Prelucrari parametri
				@contnom=isnull(@contnom,'%')
		--select (case when @tippret<>'s' then @categpret else null end)
		if object_id('tempdb.dbo.#comparativa') is not null drop table #comparativa

		-->	Preluarea datelor din inventar
		CREATE TABLE #comparativa (
			cod VARCHAR(20), stoc_scriptic FLOAT, stoc_faptic FLOAT, pret FLOAT, plusinv FLOAT, minusinv FLOAT,
			valplusinv FLOAT, valminusinv FLOAT,pretstoc float,pretam float
		)

		IF OBJECT_ID('tempdb.dbo.#grupate') is not null drop table #grupate

		CREATE TABLE #grupate (
			gestiune varchar(50), dengest varchar(150), cod varchar(20), stoc_scriptic float, stoc_faptic float, grupare varchar(50),
			valoare float, val_unit float, diferentaCantitate float, diferentaValorica float, valoareInventar float
		)

		declare @denGest varchar(1000), @parXML xml, @codGestiune varchar(20)
		declare @lista table(cod varchar(50))
		
		/** Inseram gestiunile/marcile in @lista, doar daca s-a selectat filtrul pe loc de munca */
		IF ISNULL(@locm, '') <> ''
		BEGIN
			IF @tipgest = 'D'
			BEGIN
				INSERT INTO @lista(cod)
				SELECT RTRIM(g.Cod_gestiune)
				FROM gestiuni g
				INNER JOIN AntetInventar ai ON ai.gestiune = g.Cod_gestiune AND ai.tip = 'G'
				WHERE g.detalii.value('(/row/@lm)[1]', 'varchar(50)') LIKE RTRIM(@locm) + '%'
					AND ai.data = @dData and 
					(@cGestiune is null or g.Cod_gestiune=@cGestiune)
			END
			ELSE
			BEGIN
				INSERT INTO @lista(cod)
				SELECT RTRIM(p.Marca)
				FROM personal p
				INNER JOIN AntetInventar ai ON ai.gestiune = p.Marca AND ai.tip <> 'G'
				WHERE p.Loc_de_munca LIKE RTRIM(@locm) + '%' 
					AND ai.data = @dData
					and (@cGestiune is null or p.Loc_de_munca=@cGestiune)
			END
		END
		
		IF @cGestiune is not null and not exists (select 1 from @lista where cod=@cGestiune)
			insert into @lista values(@cGestiune)

		SET @codGestiune = NULL
		SELECT TOP 1 @codGestiune = cod FROM @lista

		while @codGestiune is not null 
		begin

			select @parXML=(select @dData data, @cGrupa grupa, @codGestiune gestiune, @variantaNoua variantaNoua, (case when @tippret='s' then 0 else 1 end) cuCategorie,
							(case when @tippret<>'s' then @categpret else null end) as categatasata,@faraDocumentCorectie as faradocumentcorectie, @locatie locatie,
							@grupare_cod_pret grupare_cod_pret, (case when @standard=2 then 'F' else 'D' end) as tip_gestiune, @cont cont
						for xml raw)
		
			if @tipgest = 'D'
				select @denGest=rtrim(g.Denumire_gestiune) from gestiuni g where g.Cod_gestiune=@codGestiune
			else
				select @denGest=rtrim(nume) from personal p where p.marca=@codGestiune

			insert into #comparativa (cod, stoc_scriptic, stoc_faptic, pret, plusinv, minusinv,
				valplusinv, valminusinv,pretstoc,pretam)
			exec wGenerareInventarComparativa @parXML=@parXML
			
			insert into #grupate (gestiune, dengest, cod, stoc_scriptic, stoc_faptic, grupare,
				valoare, val_unit, diferentaCantitate, diferentaValorica, valoareInventar) 
			select
				@codGestiune as gestiune, @denGest as dengest, cod, sum(stoc_scriptic) stoc_scriptic, sum(stoc_faptic) stoc_faptic,
				cod+'|'+convert(varchar(20), (case when @grupare_cod_pret=1 then pret else 0 end)) grupare,
				sum((c.stoc_scriptic-c.stoc_faptic)*c.pret) valoare, max(c.pret) val_unit, 
				sum(c.stoc_scriptic-c.stoc_faptic) diferentaCantitate,
				sum((c.stoc_scriptic-c.stoc_faptic)*c.pret) diferentaValorica,
				sum(c.stoc_faptic*c.pret) valoareInventar
			from #comparativa c
			group by cod, (case when @grupare_cod_pret=1 then pret else 0 end)

			truncate table #comparativa

			delete from @lista where cod = @codGestiune
			set @codGestiune = null
			select top 1 @codGestiune = cod from @lista

		end

		select @cui = rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'CODFISC'
		select @ordreg = rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'ORDREG'
		select @adresa = rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'ADRESA'

		select	@cui as cui, @ordreg as ordreg, @adresa as adresa,
				rtrim(c.gestiune) gestiune, rtrim(c.dengest) as den_gest, rtrim(c.cod) cod, c.stoc_scriptic, --c.pret,
				(case when @tipgest='F' then 0 else convert(decimal(15,2), c.valoare) end) valoare, convert(decimal(17,5), c.val_unit) as val_unit,
				'1901-1-1' data, 'c' loc_de_munca,
				rtrim(n.Denumire) denumire,
				rtrim(n.um) um,
				c.stoc_faptic,
				'n' nume_lm,
				convert(decimal(15,2), c.diferentaCantitate) as diferentaCantitate,
				c.grupare,
				(case when diferentaValorica>0 or @tipgest='F' then 0 else convert(decimal(15,2), -diferentaValorica) end) as plus,
				(case when diferentaValorica<0 or @tipgest='F' then 0 else convert(decimal(15,2), diferentaValorica) end) as minus,
				(case when @tipgest='F' then 0 else convert(decimal(15,2), valoareInventar) end) valoareInventar
		from #grupate c
			left join nomencl n on c.cod=n.Cod
		where (@flt_cCod=0 or c.cod=@cCod)
			and (@flt_contnom=0 or n.Cont like @contnom)
		order by (case @ordonare when 'c' then c.cod else n.denumire end), n.denumire, c.cod
	end try
	begin catch
		set @eroare=ERROR_MESSAGE()+' (rapInventarComparativa '+convert(varchar(20),error_line())+')'
	end catch
	if object_id('tempdb.dbo.#comparativa') is not null drop table #comparativa
	if object_id('tempdb.dbo.#grupate') is not null drop table #grupate
	if object_id('tempdb.dbo.#preturi') is not null drop table #preturi

	if len(@eroare)>0 --raiserror(@eroare,16,1)
		select @eroare as den_gest, '<EROARE>' as gestiune
end
