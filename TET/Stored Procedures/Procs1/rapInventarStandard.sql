
create procedure rapInventarStandard @sesiune varchar(50)=null, @dData datetime, @cCod varchar(100)=null, @tipgest varchar(100)
		,@cGestiune varchar(100)=null,@gGestiuni varchar(20)=null		--> grup de gestiuni
		,@locm varchar(100)=null, @cont varchar(100)=null
		,@ordonare varchar(1)='c' -- ordonare articole pe cod sau denumire: c=pe cod, d=pe denumire  
		,@grupare int=0 -- grupare pe gestiune si cod: 0 sau null inseamna grupare pe gestiune, cod si pret, 1 inseamna grupare pe gestiune si cod 
		,@tippret varchar(1)='s' -- s=pret de stoc, mai poate fi v=pret de vanzare (se selecteaza o categorie de pret) sau dupa tip gestiune (de stoc sau cu amanuntul)
		,@categpret smallint=null -- categoria de pret vanzare, daca s-a optat pentru asta 
		,@locatie  varchar(40)=null
		,@contnom varchar(100)=null

as

set transaction isolation level read uncommitted
declare @eroare varchar(500), @cui varchar(50), @ordreg varchar(50), @adresa varchar(200)
begin try
	if object_id('tempdb..#preturi') is not null drop table #preturi
	if object_id('tempdb..#stocuri') is not null drop table #stocuri
	if object_id('tempdb..#final') is not null drop table #final

	select @contnom=isnull(@contnom,'%')
	declare @parXML xml
	select @parXML=(select
		--(case when @tipgest='F' then null else convert(varchar(20),@dData,102) end) 
			convert(varchar(20),@dData,102) dDataJos,
		convert(varchar(20),@dData,102) dDataSus,
		@cCod cCod, @cGestiune cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, @tipgest TipStoc, @cont cCont
			,@locatie Locatie
			,@locm lm, (case when @tipgest<>'D' then null else @gGestiuni end) as grupGestiuni
			,@sesiune sesiune
	for xml raw)
			
	if object_id('tempdb..#docstoc') is not null drop table #docstoc
		create table #docstoc(subunitate varchar(9))
		exec pStocuri_tabela
	 
	exec pstoc @sesiune=@sesiune, @parxml=@parxml
	
	create table #stocuri(subunitate varchar(20), cod varchar(20), gestiune varchar(20), cod_intrare varchar(20), pret float,
		tip_gestiune varchar(1), data datetime, stoc float, loc_de_munca varchar(20), cont varchar(20),pret_cu_amanuntul float,
		data_expirarii datetime)
		
	insert into #stocuri(subunitate, cod, gestiune, cod_intrare, pret, tip_gestiune, data, stoc, loc_de_munca, cont,pret_cu_amanuntul, data_expirarii)
	select subunitate, cod, gestiune, cod_intrare, pret, tip_gestiune, data, (case when tip_miscare='E' then -1 else 1 end)*stoc stoc, loc_de_munca, cont, pret_cu_amanuntul, data_expirarii
	from #docstoc
	
	select @cui = rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'CODFISC'
	select @ordreg = rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'ORDREG'
	select @adresa = rtrim(Val_alfanumerica) from par where Tip_parametru = 'GE' and Parametru = 'ADRESA'

	select sum(r.stoc * (CASE WHEN @tipgest = 'A' THEN r.pret_cu_amanuntul ELSE r.pret END)) valstoc,
		@tipgest tip_stoc, r.cod, max(n.denumire) as denprod, max(n.um) as um, 
		r.gestiune,
		max(ltrim(rtrim(case @tipgest when 'F' then p.nume /*when 'T' then t.Denumire*/ else g.denumire_gestiune end))) as dengest,
		r.cod_intrare as cod_intrare, 
		(case @tippret when 's' then min(r.pret ) --Pret de stoc
			--when 'v' then max(pr.pret_amanunt) --Pret vanzare pe o categorie din wIaPreturi 
			else	--In functie de tipul gestiunii
				(case when max(r.tip_gestiune)='A' then max(r.Pret_cu_amanuntul) else max(r.pret) end) 
		end) as pret,
		min(r.data) as data, sum(r.stoc) as stoc, max(r.loc_de_munca) as loc_de_munca,MAX(l.Denumire) as nume_lm,
		max(rtrim(r.cont)) as cont, --max(rtrim(c.Denumire_cont)) as Denumire_cont,
		--min(isnull(sl.stoc_min,slstd.stoc_min)) as stocmin,
		max(n.grupa) grupa,
/*		convert(varchar(20),min(r.data),103)+
			(case when @tipgest='F' then ' -> '+convert(varchar(20),min(r.data_expirarii),103)
				else '' end)+' - '+
			(case when @grupare=1 then max(rtrim(r.gestiune)+'-'+
						rtrim((case when @tipgest='F' then p.nume else g.denumire_gestiune end))
						)
					else rtrim(r.cont) end) as detalii,*/
--		min(r.data_expirarii) data_expirarii,
--		max(rtrim(gr.denumire)) denGrupa,
		--rtrim(case when @ordonare='c' then (case @grupare when 0 then max(r.gestiune) else max(r.loc_de_munca) end)	else (case @grupare	when 0 then max(case @tipgest when 'F' then p.nume /*when 'T' then t.Denumire*/ else g.denumire_gestiune end) else max(l.denumire) end) end) ord1,
		rtrim(max(r.gestiune)) ord1,
		rtrim(case when @ordonare='c' then max(r.cod) else max(n.denumire) end) ord2,
		--rtrim(case when @gruppret=0 then max(r.cod_intrare) else '' end) as ordCodIntrare,
		max(rtrim(n.um_1)) um_1,
		convert(decimal(15,2),sum(case when n.um_1='' or abs(coeficient_conversie_1)<0.001 then '' else r.stoc/n.coeficient_conversie_1 end)) cantitate_1,
		max(rtrim(n.um_2)) um_2,
		convert(decimal(15,2),sum(case when n.um_2='' or abs(coeficient_conversie_2)<0.001 then '' else r.stoc/n.coeficient_conversie_2 end)) cantitate_2
	into #final
	from #stocuri r
		--left join #preturi pr on pr.Cod=r.cod
		left outer join nomencl n on r.cod=n.cod
		left join gestiuni g on r.subunitate=g.subunitate and r.gestiune=g.cod_gestiune
		left join lm l on rtrim(r.loc_de_munca)=rtrim(l.Cod) --and @tipgest='F'
		left join personal p on r.gestiune=p.marca
	where (@contnom is null or n.cont like @contnom)
		--(isnull(n.denumire,'')='' or n.denumire like '%'+ isnull(@den,'')+'%')
		--and (@gGestiuni is null or r.gestiune like @gGestiuni+'%')
		--and (@grupa is null or n.grupa like @grupa)
		--and (@furnizor_nomenclator is null or @furnizor_nomenclator=n.furnizor)
	group by r.cod, r.gestiune, --(case when @gruppret=0 then r.cod_intrare else '' end),
		r.pret, r.cod_intrare--, l.cod, r.cont
		
	delete #final where abs(stoc)<0.01
	/*
	update fs set pret = fs.valstoc / fs.stoc
		FROM #final fs
	
		create table #preturi(cod varchar(20),nestlevel int)
		
		insert into #preturi
		select s.cod, @@NESTLEVEL
		from #stocuri s
		group by s.cod

		exec CreazaDiezPreturi
		
		if (@tippret='V')
		begin
			declare @px xml
			select @px=(select @categPret as categoriePret, @dData as data, @cGestiune as gestiune for xml raw)
			exec wIaPreturi @sesiune=null,@parXML=@px
		end
	*/
	select row_number() over (partition by r.gestiune order by (case when @ordonare = 'c' then r.cod else r.denprod end)) as nrcrt,
		@cui as cui, @ordreg as ordreg, @adresa as adresa, r.gestiune, rtrim(r.cod) cod, sum(r.stoc) stoc_scriptic, 
		(case when @grupare=0 then max(r.pret) when sum(r.stoc)=0 then 0 else sum(r.stoc*r.pret)/sum(r.stoc) end) pret,
		(case when @grupare=0 then max(r.pret) when sum(r.stoc)=0 then 0 else sum(r.stoc*r.pret)/sum(r.stoc) end) val_unit,	--> val_unit se calcula cu ceva figuri prin wGenerareInventarComparativa; am simplificat, dar nu e sigura.
		max(r.data) as data, max(r.loc_de_munca) loc_de_munca, max(r.denprod) Denumire, max(r.um) um, max(dengest) as den_gest, max(r.nume_lm) nume_lm,
		max(r.cod_intrare) as cod_intrare
	from #final r
	group by r.gestiune, r.cod, r.denprod, /*r.data,*/ (case when @grupare=0 then r.pret else 0 end)	-- am scos gruparea dupa data. Daca se va cere ar fi bine sa se puna ca si optiune.
	having abs(sum(r.stoc))>0.01
	order by max(ord1), max(ord2)
end try
begin catch
	set @eroare='rapInventarStandard: '+ERROR_MESSAGE()
end catch

if object_id('tempdb..#preturi') is not null drop table #preturi
if object_id('tempdb..#stocuri') is not null drop table #stocuri
if object_id('tempdb..#final') is not null drop table #final

if len(@eroare)>0 --raiserror(@eroare,16,1)
		select '<EROARE>' gestiune, @eroare den_gest
