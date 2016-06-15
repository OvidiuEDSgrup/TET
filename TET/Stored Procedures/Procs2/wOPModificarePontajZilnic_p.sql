create procedure wOPModificarePontajZilnic_p (@sesiune varchar(50), @parXML xml='<row/>')
as
begin try

	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @mesaj varchar(1000), @datalunii datetime, @dataJos datetime, @dataSus datetime, @marca varchar(6), @densalariat varchar(100), @lm varchar(20),
			@orelucrate int, @osupl1 int, @osupl2 int, @osupl3 int, @osupl4 int, @orenoapte int

	select	@datalunii = @parXML.value('(/row/@data)[1]', 'datetime'),
			@marca = rtrim(@parXML.value('(/*/*/@marca)[1]', 'varchar(6)')),
			@densalariat = rtrim(@parXML.value('(/*/*/@densalariat)[1]', 'varchar(100)'))
	select @lm=loc_de_munca from personal where marca=@marca

	select @dataJos = dbo.BOM(@datalunii)
	select @dataSus = dbo.EOM(@datalunii)

	if isnull(@marca,'')=''
		raiserror('Operatie de modificare date pontaj nepermisa pe loc de munca, selectati un salariat de pe loc de munca!',16,1)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	if object_id('tempdb..#pontaj_grid') is not null drop table #pontaj_grid
	if object_id('tempdb..#regimlucru') is not null drop table #regimlucru

	select marca, rl into #regimlucru
	from fDate_pontaj_automat (@datajos, @datasus, @datasus, 'RL', isnull(@marca,''), 0, 0) po

	select * into #pontaj_grid
	from pontaj_zilnic
	where marca=@marca and data between @dataJos and @dataSus

	insert into #pontaj_grid (data, marca, loc_de_munca, tip_ore, ore)
	select data, @marca, @lm, '', 0
	from fCalendar (@datajos,@datasus) cl
	where not exists (select 1 from #pontaj_grid p where p.data=cl.data and p.marca=@marca)

	select	@orelucrate=nullif(sum(case when tip_ore in ('OL','OD') then ore else 0 end),0), 
			@osupl1=nullif(sum(case when tip_ore='S1' then ore else 0 end),0), 
			@osupl2=nullif(sum(case when tip_ore='S2' then ore else 0 end),0), 
			@osupl3=nullif(sum(case when tip_ore='S3' then ore else 0 end),0), 
			@osupl4=nullif(sum(case when tip_ore='S4' then ore else 0 end),0),
			@orenoapte=nullif(sum(case when tip_ore='NO' then ore else 0 end),0)
	from #pontaj_grid
	where tip_ore in ('OL','OD') or tip_ore like 'S%' or tip_ore='NO'

	select convert(varchar(10),@datajos,101) as datajos, convert(varchar(10),@datasus,101) as datasus, 
		rtrim(@marca) as marca, rtrim(@densalariat) as densalariat, 
		@orelucrate as orelucrate, @osupl1 as osupl1, @osupl2 as osupl2, @osupl3 as osupl3, @osupl4 as osupl4, @orenoapte as orenoapte
	for xml raw, root('Date')

	SELECT (   
		SELECT rtrim(p.marca) as marca, convert(varchar(10),p.data,101) as data, 
			left(cl.zi_alfa,1) as zi, rl.rl as rl, 
			p.tip_ore as tipore, 
			(case when p.tip_ore in ('OL','OD') then ore end) as ore, 
			(case when p.tip_ore='OD' then 1 else 0 end) as diurna,
			(case when p.tip_ore='CM' then 1 else 0 end) as cm,
			(case when p.tip_ore='CO' then 1 else 0 end) as co,
			(case when p.tip_ore='LP' then 1 else 0 end) as intr1,
			(case when p.tip_ore='FS' then 1 else 0 end) as cfs,
			(case when p.tip_ore='IN' then 1 else 0 end) as invoiri,
			(case when p.tip_ore='NE' then 1 else 0 end) as nemotivate,
			(case when p.tip_ore='OB' then 1 else 0 end) as obligatii,
			(case when cs.data is not null then '#CC0033' when left(cl.zi_alfa,1) in ('S','D') then '#FF0000' else '#000000' end) as culoare
		FROM #pontaj_grid p
			left join fCalendar (@datajos, @datasus) cl on cl.data=p.data
			left join calendar cs on cs.data=p.data
			left join #regimlucru rl on rl.marca=p.marca
		where p.marca=@marca 
			and p.tip_ore not in ('S1','S2','S3','S4','NO')
		order by data
		FOR XML RAW, TYPE  
		)  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')

	select '1' AS areDetaliiXml FOR XML raw, root('Mesaje')

end try

begin catch
	set @mesaj = error_message() + ' (' + object_name(@@PROCID) + ')'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@mesaj, 11, 1)
end catch
