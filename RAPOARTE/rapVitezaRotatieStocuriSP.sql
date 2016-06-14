/**
	declare @datajos datetime,@eomDStart datetime,@datasus datetime,@cod varchar(20), @gestiune varchar(20), @grupa varchar(20)=null
	select @datajos='05/01/2012', @datasus='08/31/2012', @cod=null, @gestiune='CJ04'--'01DKPGBLT1110       '
			, @grupa=''
	exec rapVitezaRotatieStocuri @datajos=@datajos, @datasus=@datasus, @cod=@cod, @gestiune=@gestiune, @grupa=@grupa
*/
--***
/*
if exists (select 1 from sysobjects where name='rapVitezaRotatieStocuri')
	drop procedure rapVitezaRotatieStocuri
go
--***
create procedure rapVitezaRotatieStocuri(--*/ declare
@sesiune varchar(50)=null, @datajos datetime, @datasus datetime, @cod varchar(20)=null, @grupa varchar(20)=null,
	@gestiune varchar(20)=null, @centralizare int=0,	--> centralizare: 0=toate, 1=fara gestiuni 
	@cantitativ bit=0,	--> 0=valoric, 1=cantitativ
	@locatie varchar(30)=null
--/*
select @datajos='2013-12-10', @datasus='2014-03-10', @cod=null, @gestiune=null--'01DKPGBLT1110       '
			, @grupa=null
--*/)as
begin

declare @nrzile int, @eomDStart datetime
select	@nrzile=datediff(day,@datasus,@datajos)+1, @eomDStart=dbo.eom(@datajos)

create table tempdb..rotatii(data_lunii datetime,cod varchar(20),gestiune varchar(20),stoc_initial float,intrari float,iesiri float,stoc float, nume_luna varchar(20))
/*
		declare @cCod char(20), @cCodi char(20), @GrCod int, @GrGest int, @GrCodi int, @TipStoc char(1), @cCont char(13), @grupa char(13), 
			@Locatie char(30), @LM char(9), @Comanda char(40), @Contract char(20), @Furnizor char(13), @Lot char(20)

		select @cCod=@cod, @gestiune='CJ04'/*null*/, @cCodi=null, @GrCod=null, @GrGest=null, @GrCodi=null, @TipStoc=null, @cCont='', @grupa='%'
			,@Locatie='', @LM='', @Comanda='', @Contract='', @Furnizor='', @Lot=''*/

	/*inseram in rotatii stocul initial*/
	select cod, gestiune, in_out, cantitate, (case when @cantitativ=1 then 1 else pret end) pret, data
	into tempdb..fstocuri
	from dbo.fStocuri(@datajos,@datasus,@Cod,@gestiune,null,@grupa,'','', 0, @locatie, '', '', '', '', '', @sesiune)

	insert into tempdb..rotatii (data_lunii, cod, gestiune, stoc_initial, intrari, iesiri, stoc, nume_luna)
	select cs.data_lunii,fs.cod,(case when @centralizare=0 then fs.gestiune else '' end) gestiune, 0 as stoc_initial,
		0 as intrari,
		0 as iesiri,
		0 as stoc, max(rtrim(cs.lunaalfa)+' '+convert(varchar(20), cs.An))
	from calstd cs,tempdb..fstocuri fs
	where cs.data between @datajos and @datasus
	group by cs.data_lunii, fs.gestiune, fs.cod

	update tempdb..rotatii set 
		stoc_initial=inties.stoc_initial
	from (
		select (case when @centralizare=0 then fs.gestiune else '' end) gestiune,fs.cod,
		sum((case when fs.in_out=1 then 1
				  when fs.in_out=2 then 1
				  when in_out=3 then -1
					else 0 end)*fs.cantitate*fs.pret) as stoc_initial
		from tempdb..fstocuri fs
		where fs.data<@datajos 
		group by (case when @centralizare=0 then fs.gestiune else '' end),fs.cod) 
			inties,tempdb..rotatii 
	where inties.gestiune=tempdb..rotatii.gestiune and inties.cod=tempdb..rotatii.cod and tempdb..rotatii.data_lunii=@eomDStart

	
	update tempdb..rotatii set 
		intrari=inties.intrari,iesiri=inties.iesiri
	from (
		select cs.data_lunii,(case when @centralizare=0 then fs.gestiune else '' end) gestiune,fs.cod,sum(case when fs.in_out=2 then cantitate*pret else 0 end) as intrari,
		sum(case when fs.in_out=3 then cantitate*pret else 0 end) as iesiri
		from tempdb..fstocuri fs inner join calstd cs on cs.data=fs.data
		where fs.data between @datajos and @datasus
		group by cs.data_lunii,(case when @centralizare=0 then fs.gestiune else '' end),fs.cod) inties,tempdb..rotatii where inties.gestiune=tempdb..rotatii.gestiune and inties.cod=tempdb..rotatii.cod and inties.data_lunii=tempdb..rotatii.data_lunii

	declare @stoc float,@codsigestiune varchar(50),@stocinitial float
	select @stoc=0,@stocinitial=0,@codsigestiune=''

	
	declare @tData datetime,@tCod varchar(20),@tGestiune varchar(20),@tStoc_initial float,@tIntrari float,@tIesiri float,@tstoc float,@nF int,@tCodSiGestiune varchar(100)
	select @tCodSiGestiune=''
	declare rotCursor cursor for
		select data_lunii,cod,gestiune,stoc_initial,intrari,iesiri 
		from tempdb..rotatii
		order by gestiune,cod,data_lunii
	open rotCursor
	fetch next from rotCursor into
		@tdata,@tcod,@tgestiune,@tstoc_initial,@tintrari,@tiesiri
	set @nF=@@FETCH_STATUS
	while @nF=0
	begin
		if @tcod+@tgestiune!=@tCodSiGestiune
			select @tStoc=@tStoc_initial,@tCodSiGestiune=@tCod+@tGestiune

		update tempdb..rotatii
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
		into tempdb..coduri
		from tempdb..rotatii
	group by gestiune,cod

	select gestiune,count(*) as nrart
	into tempdb..gestiuni
	from tempdb..coduri group by gestiune
	
	--alter table tempdb..coduri add categorie char(1),culoare varchar(20)

	update tempdb..coduri set
		categorie=(case when numar<0.20*tempdb..gestiuni.nrart then 'A'
					when numar between 0.2000001*tempdb..gestiuni.nrart and 0.50*tempdb..gestiuni.nrart then 'B'
					else 'C' end)
	from tempdb..coduri,tempdb..gestiuni where tempdb..coduri.gestiune=tempdb..gestiuni.gestiune

	
	update tempdb..coduri set culoare=f.culoare
		from tempdb..coduri,frapvitezarotatiestocuriculori() f
		where tempdb..coduri.viteza>f.zi_jos and tempdb..coduri.viteza<=f.zi_sus

	select r.data_lunii, rtrim(r.cod) cod, rtrim(r.gestiune) gestiune, r.stoc_initial, r.intrari, r.iesiri, r.stoc, r.nume_luna,
		c.viteza,c.culoare, c.categorie, rtrim(isnull(g.Denumire_gestiune,'Fara grupare gestiune')) as denumire_gestiune,
			rtrim(n.Denumire) denumire_produs
	from tempdb..rotatii r
		inner join tempdb..coduri c on r.gestiune=c.gestiune and r.cod=c.cod
		left join gestiuni g on r.gestiune=g.Cod_gestiune
		left join nomencl n on r.cod=n.Cod
	order by r.gestiune, c.categorie, r.cod, c.numar, r.data_lunii

	--if object_id('tempdb..gestiuni') is not null drop table tempdb..gestiuni
	--if object_id('tempdb..coduri') is not null drop table tempdb..coduri
	--if object_id('tempdb..rotatii') is not null drop table tempdb..rotatii
	--if object_id('tempdb..fstocuri') is not null drop table tempdb..fstocuri
end