--***
create procedure rapVitezaRotatieStocuri(@sesiune varchar(50)=null, @datajos datetime, @datasus datetime, @cod varchar(20)=null, @grupa varchar(20)=null,
	@gestiune varchar(20)=null, @centralizare int=0,	--> centralizare: 0=toate, 1=fara gestiuni 
	@cantitativ bit=0,	--> 0=valoric, 1=cantitativ
	@locatie varchar(30)=null
	)
as
begin

declare @nrzile int, @eomDStart datetime
select	@nrzile=datediff(day,@datasus,@datajos)+1, @eomDStart=dbo.eom(@datajos)

create table #rotatii(data_lunii datetime,cod varchar(20),gestiune varchar(20),stoc_initial float,intrari float,iesiri float,stoc float, nume_luna varchar(20))
/*
		declare @cCod char(20), @cCodi char(20), @GrCod int, @GrGest int, @GrCodi int, @TipStoc char(1), @cCont char(13), @grupa char(13), 
			@Locatie char(30), @LM char(9), @Comanda char(40), @Contract char(20), @Furnizor char(13), @Lot char(20)

		select @cCod=@cod, @gestiune='CJ04'/*null*/, @cCodi=null, @GrCod=null, @GrGest=null, @GrCodi=null, @TipStoc=null, @cCont='', @grupa='%'
			,@Locatie='', @LM='', @Comanda='', @Contract='', @Furnizor='', @Lot=''*/

	/*inseram in rotatii stocul initial*/
		declare @p xml
	select @p=(select @datajos dDataJos, @datasus dDataSus, @Cod cCod, @gestiune cGestiune, @grupa cGrupa, @locatie Locatie
		,@sesiune sesiune
	for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p
	select cod, gestiune, in_out, cantitate, (case when @cantitativ=1 then 1 else pret end) pret, data
	into #fstocuri
	from --dbo.fStocuri(@datajos,@datasus,@Cod,@gestiune,null,@grupa,'','', 0, @locatie, '', '', '', '', '', @sesiune)
		#docstoc
	
	select * into #calstd from fCalendar(@datajos,@datasus)
	
	insert into #rotatii (data_lunii, cod, gestiune, stoc_initial, intrari, iesiri, stoc, nume_luna)
	select cs.data_lunii,fs.cod,(case when @centralizare=0 then fs.gestiune else '' end) gestiune, 0 as stoc_initial,
		0 as intrari,
		0 as iesiri,
		0 as stoc, max(rtrim(cs.lunaalfa)+' '+convert(varchar(20), cs.An))
	from #calstd cs,#fstocuri fs
	where cs.data between @datajos and @datasus
	group by cs.data_lunii, fs.gestiune, fs.cod

	update #rotatii set 
		stoc_initial=inties.stoc_initial
	from (
		select (case when @centralizare=0 then fs.gestiune else '' end) gestiune,fs.cod,
		sum((case when fs.in_out=1 then 1
				  when fs.in_out=2 then 1
				  when in_out=3 then -1
					else 0 end)*fs.cantitate*fs.pret) as stoc_initial
		from #fstocuri fs
		where fs.data<@datajos 
		group by (case when @centralizare=0 then fs.gestiune else '' end),fs.cod) 
			inties,#rotatii where inties.gestiune=#rotatii.gestiune and inties.cod=#rotatii.cod and #rotatii.data_lunii=@eomDStart

	
	update #rotatii set 
		intrari=inties.intrari,iesiri=inties.iesiri
	from (
		select cs.data_lunii,(case when @centralizare=0 then fs.gestiune else '' end) gestiune,fs.cod,sum(case when fs.in_out=2 then cantitate*pret else 0 end) as intrari,
		sum(case when fs.in_out=3 then cantitate*pret else 0 end) as iesiri
		from #fstocuri fs inner join #calstd cs on cs.data=fs.data
		where fs.data between @datajos and @datasus
		group by cs.data_lunii,(case when @centralizare=0 then fs.gestiune else '' end),fs.cod) inties,#rotatii where inties.gestiune=#rotatii.gestiune and inties.cod=#rotatii.cod and inties.data_lunii=#rotatii.data_lunii

	declare @stoc float,@codsigestiune varchar(50),@stocinitial float
	select @stoc=0,@stocinitial=0,@codsigestiune=''

	
	declare @tData datetime,@tCod varchar(20),@tGestiune varchar(20),@tStoc_initial float,@tIntrari float,@tIesiri float,@tstoc float,@nF int,@tCodSiGestiune varchar(100)
	select @tCodSiGestiune=''
	declare rotCursor cursor for
		select data_lunii,cod,gestiune,stoc_initial,intrari,iesiri 
		from #rotatii
		order by gestiune,cod,data_lunii
	open rotCursor
	fetch next from rotCursor into
		@tdata,@tcod,@tgestiune,@tstoc_initial,@tintrari,@tiesiri
	set @nF=@@FETCH_STATUS
	while @nF=0
	begin
		if @tcod+@tgestiune!=@tCodSiGestiune
			select @tStoc=@tStoc_initial,@tCodSiGestiune=@tCod+@tGestiune

		update #rotatii
			set stoc_initial=@tstoc,
				stoc=@tstoc+intrari-iesiri
			where data_lunii=@tData and cod=@tCod and gestiune=@tGestiune

		select @tstoc=@tstoc+@tintrari-@tiesiri

		fetch next from rotCursor into
			@tdata,@tcod,@tgestiune,@tstoc_initial,@tintrari,@tiesiri
		set @nF=@@FETCH_STATUS

	end
	close rotCursor
	deallocate rotCursor


	select gestiune,cod,
		(case when abs(avg(iesiri))>0.01 then avg(stoc)/avg(iesiri) else avg(iesiri) end)*365/12 as viteza,
		row_number() over (partition by gestiune order by sum(iesiri) desc) numar
		into #coduri
		from #rotatii
	group by gestiune,cod

	select gestiune,count(*) as nrart
	into #gestiuni
	from #coduri group by gestiune
	
	alter table #coduri add categorie char(1),culoare varchar(20)

	update #coduri set
		categorie=(case when numar<0.20*#gestiuni.nrart then 'A'
					when numar between 0.2000001*#gestiuni.nrart and 0.50*#gestiuni.nrart then 'B'
					else 'C' end)
	from #coduri,#gestiuni where #coduri.gestiune=#gestiuni.gestiune

	
	update #coduri set culoare=f.culoare
		from #coduri,frapvitezarotatiestocuriculori() f
		where #coduri.viteza>f.zi_jos and #coduri.viteza<=f.zi_sus

	select r.data_lunii, rtrim(r.cod) cod, rtrim(r.gestiune) gestiune, r.stoc_initial, r.intrari, r.iesiri, r.stoc, r.nume_luna,
		c.viteza,c.culoare, c.categorie, rtrim(isnull(g.Denumire_gestiune,'Fara grupare gestiune')) as denumire_gestiune,
			rtrim(n.Denumire) denumire_produs
	from #rotatii r
		inner join #coduri c on r.gestiune=c.gestiune and r.cod=c.cod
		left join gestiuni g on r.gestiune=g.Cod_gestiune
		left join nomencl n on r.cod=n.Cod
	order by r.gestiune, c.categorie, r.cod, c.numar, r.data_lunii

	if object_id('tempdb..#gestiuni') is not null drop table #gestiuni
	if object_id('tempdb..#coduri') is not null drop table #coduri
	if object_id('tempdb..#rotatii') is not null drop table #rotatii
	if object_id('tempdb..#fstocuri') is not null drop table #fstocuri
	if object_id('tempdb..#calstd') is not null drop table #calstd
end
