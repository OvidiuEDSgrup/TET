--***
create procedure  EvolutieStoc @sesiune varchar(50)='', @dDataJos datetime, @dDataSus datetime, @cCod char(20)=null, @cGestiune char(9)=null, @parXML xml=null
as

set transaction isolation level read uncommitted
declare @eroare varchar(max)
select @eroare=''
begin try

	if OBJECT_ID('tempdb..#evstoc') is not null
		drop table #evstoc

	declare @lPM int,@cGestExcepPM char(1000),@dDataIstoric datetime,@bomDIstoric datetime,@cSub char(13), @lot varchar(100), @tipvalori varchar(50)
	declare @nAnInc int,@nLunaInc int
	declare @dData datetime,@cDenProd char(200),@cDenGest char(100),@nStoc float, @denprodus varchar(500), @denGest varchar(500)

	if @cGestiune=''
		set @cGestiune=null
	select	@lot = @parXML.value('/row[1]/@lot','varchar(100)'),
			@tipvalori = @parXML.value('/row[1]/@tipvalori','varchar(100)')

	declare @p xml
	select @p=(select @dDataJos dDataJos, @dDataSus dDataSus, @cCod cCod, @cGestiune cGestiune, 0 Corelatii, @lot lot  for xml raw)

	if object_id('tempdb..#docstoc') is not null 
		drop table #docstoc
	create table #docstoc(subunitate varchar(9))

	exec pStocuri_tabela
	exec pstoc @sesiune=@sesiune, @parxml=@p

	if @cGestiune is null
	begin
		delete from #docstoc where tip_document in ('TI', 'TE')
		update #docstoc set gestiune=''
		set @denGest = 'GLOBAL FIRMA'
	end

	-- documentele cu AI/AE cu aceeasi cantitate nu sunt miscari efective, ci reglaje diverse
	if object_id('tempdb..#manevraPeZile') is not null 
		drop table #manevraPeZile
	select data, sum(case when tip_document='AI' then 1 else -1 end * cantitate) cantitate
		into #manevraPeZile
	from #docstoc d
	where tip_document in ('AI', 'AE')
	group by data

	delete from #manevrapezile where round(cantitate,3)<>0

	delete d
	from #docstoc d, #manevrapezile m
	where d.data=m.data and tip_document in ('AI', 'AE')

	drop table #manevraPeZile

	select @denprodus = rtrim(n.denumire)+' / '+rtrim(n.um)
	from nomencl n
	where n.cod=@cCod

	select @denGest = rtrim(denumire_gestiune)
	from gestiuni g 
	where g.Cod_gestiune=@cGestiune

	declare @si decimal(15,2), @sf decimal(15,2)
	set @si = isnull((select sum(case	when in_out=1 then 1 
									when in_out=2  then 1 
									when in_out=3  then -1 
									else 0 end * 
								case when @tipvalori = 'valoare' then cantitate*pret when @tipvalori = 'cantitate um2' then cantitate_um2 else cantitate end)
					from #docstoc where data<@dDataJos or in_out=1),0)
		
	delete from #docstoc where data<@dDataJos or in_out=1

	select 
		row_number() over (order by data, in_out, tip_document, numar_document, numar_pozitie) nrcrt,
		data,
		tip_document, 
		numar_document, 
		convert(decimal(15,3),0) as stoci,
		case when in_out=2 then case when @tipvalori = 'valoare' then cantitate*pret when @tipvalori = 'cantitate um2' then cantitate_um2 else cantitate end else 0 end as intrari, 
		case when in_out=3 then case when @tipvalori = 'valoare' then cantitate*pret when @tipvalori = 'cantitate um2' then cantitate_um2 else cantitate end else 0 end as iesiri,
		--@si+sum(case when in_out=2 then case when @tipvalori = 'valoare' then cantitate*pret when @tipvalori = 'cantitate um2' then cantitate_um2 else cantitate end else 0 end - 
		--		case when in_out=3 then case when @tipvalori = 'valoare' then cantitate*pret when @tipvalori = 'cantitate um2' then cantitate_um2 else cantitate end else 0 end) 
		--			over (order by data,in_out, tip_document, numar_document, numar_pozitie) stocf,
		convert(decimal(15,3),0) as stocf,
		convert(decimal(15,3),0) as stocizi,
	convert(decimal(15,3),0) as intrarizi,
	convert(decimal(15,3),0) as iesirizi,
	convert(decimal(15,3),0) as stocfzi,
	convert(decimal(15,3),0) as stociluna,
	convert(decimal(15,3),0) as intrariluna,
	convert(decimal(15,3),0) as iesiriluna,
	convert(decimal(15,3),0) as stocfluna			
	into #evstoc
	from #docstoc r

	CREATE UNIQUE INDEX IX_prelucrareEvoStoc on #evstoc (nrcrt)

	update d
		set stoci=isnull(dp.stoci, @si), 
			stocf=isnull(dp.stoci, @si)+isnull(intrari,0)-isnull(iesiri,0)
	from #evstoc d
	outer apply (select isnull(@si,0) + sum(isnull(intrari,0) - isnull(iesiri,0)) stoci  from #evstoc dp where dp.nrcrt<d.nrcrt) dp
	
	--update d
	--	set stoci=stocf-intrari+iesiri
	--from #evstoc d
		
	select data ziua, min(nrcrt) idminim, max(nrcrt) idmaxim, sum(intrari) intrari, sum(iesiri) iesiri, convert(decimal(15,3),0) as stocinceput, convert(decimal(15,3),0) as stocfinal
	into #zilnic
	from #evstoc d
	group by data
		
	select dbo.bom(ziua) luna, min(idminim) idminim, max(idmaxim) idmaxim, sum(intrari) intrari, sum(iesiri) iesiri, convert(decimal(15,3),0) as stocinceput, convert(decimal(15,3),0) as stocfinal
	into #lunar
	from #zilnic d
	group by dbo.bom(ziua)

	update z
		set stocinceput = di.stoci, 
			stocfinal = df.stocf
	from #zilnic z, #evstoc di, #evstoc df
	where z.idminim=di.nrcrt and z.idmaxim=df.nrcrt

	update l
		set stocinceput = di.stocinceput, 
			stocfinal = df.stocfinal
	from #lunar l, #zilnic di, #zilnic df
	where l.idminim=di.idminim and l.idmaxim=df.idmaxim

	update d
		set stocizi=z.stocinceput,
			intrarizi=z.intrari,
			iesirizi=z.iesiri,
			stocfzi=z.stocfinal,
			stociluna=l.stocinceput,
			intrariluna=l.intrari,
			iesiriluna=l.iesiri,
			stocfluna=l.stocfinal
	from #evstoc d, #lunar l, #zilnic z
	where d.data=z.ziua and dbo.bom(d.data)=l.luna
		
	select *, @denGest DenGest, @denprodus DenProd, convert(char(4), year(data))+convert(varchar(2),DATEPART(mm, data)) AS lunaGr,
		dbo.fDenumireLuna(data) + ' '+convert(char(4), year(data)) denLuna
	from #evstoc

end try
begin catch
	select @eroare=error_message()+' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if object_id('tempdb..#docstoc') is not null 
	drop table #docstoc

if len(@eroare)>0
select '<EROARE>' as DenProd, @eroare as DenGest
