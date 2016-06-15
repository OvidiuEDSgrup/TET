create procedure wOPModificarePontajZilnic (@sesiune varchar(50), @parXML xml='<row/>')
as
begin try 

	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @mesaj varchar(1000), 
			@marca varchar(6), @lm varchar(9), @datajos datetime, @datasus datetime, @iDoc int, 
			@oresupl1 int, @oresupl2 int, @oresupl3 int, @oresupl4 int, @orenoapte int

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	select	
			@marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)'),
			@lm = @parXML.value('(/*/@lm)[1]', 'varchar(9)'),
			@datajos = rtrim(@parXML.value('(/*/@datajos)[1]', 'datetime')),
			@datasus = rtrim(@parXML.value('(/*/@datasus)[1]', 'datetime')),
			@oresupl1 = @parXML.value('(/*/@osupl1)[1]', 'int'),
			@oresupl2 = @parXML.value('(/*/@osupl2)[1]', 'int'),
			@oresupl3 = @parXML.value('(/*/@osupl3)[1]', 'int'),
			@oresupl4 = @parXML.value('(/*/@osupl4)[1]', 'int'),
			@orenoapte = @parXML.value('(/*/@orenoapte)[1]', 'int')

-->	citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPontaj') IS NOT NULL
		DROP TABLE #xmlPontaj
	if object_id('tempdb..#pontaj_zilnic') is not null 
		drop table #pontaj_zilnic

	select marca, rl into #regimlucru
	from fDate_pontaj_automat (@datajos, @datasus, @datasus, 'RL', @marca, 0, 0) po

	SELECT data, rtrim(marca) as marca, ore as ore, diurna, cm, co, intr1, cfs, invoiri, nemotivate, obligatii, subtip as subtip, tipore as tip_ore
	INTO #xmlPontaj
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		data datetime '@data'
		,marca varchar(20) '@marca'
		,tipore varchar(20) '@tipore'
		,ore float '@ore' 
		,diurna int '@diurna'
		,cm int '@cm'
		,co int '@co'
		,intr1 int '@intr1'
		,cfs int '@cfs'
		,invoiri int '@invoiri'
		,nemotivate int '@nemotivate'
		,obligatii int '@obligatii'
		,subtip varchar(2) '@subtip'
		,detalii xml 'detalii/row'
	)
	
	EXEC sp_xml_removedocument @iDoc

	if exists (select 1 from #xmlPontaj where cm+co+intr1+cfs+invoiri+nemotivate+obligatii+(case when ore<>0 and tip_ore in ('OL','OD') then 1 else 0 end)>1)
	begin
		declare @dataErr datetime, @mesajErr varchar(1000)
		select top 1 @dataErr=data from #xmlPontaj where cm+co+intr1+cfs+invoiri+nemotivate+obligatii+(case when ore<>0 and tip_ore in ('OL','OD') then 1 else 0 end)>1
		set @mesajErr='Ati pontat pe data de '+convert(varchar(10),@dataErr,104)+' mai mult de un tip de ore!'
		raiserror (@mesajErr,11,1)
	end

	update x 
		set tip_ore=
			(case when cm=1 then 'CM' when co=1 then 'CO' 
					when intr1=1 then 'LP' when cfs=1 then 'FS' when invoiri=1 then 'IN' 
					when nemotivate=1 then 'NE' when obligatii=1 then 'OB' 
					when cm+co+intr1+cfs+invoiri+nemotivate+obligatii=0 then (case when diurna=1 then 'OD' else 'OL' end) when isnull(nullif(tip_ore,''),'OL')='OL' then 'OL' end),
			x.ore=(case when cm=1 or co=1 or intr1=1 or cfs=1 or invoiri=1 or nemotivate=1 or obligatii=1 then rl.rl else x.ore end)
	from #xmlPontaj x
		inner join #regimlucru rl on rl.marca=x.marca

	insert into #xmlPontaj (data, marca, ore, cm, co, intr1, cfs, invoiri, nemotivate, obligatii, subtip, tip_ore)
	select @datasus, @marca, @oresupl1, 0, 0, 0, 0, 0, 0, 0, null, 'S1' where @oresupl1 is not null
	union all 
	select @datasus, @marca, @oresupl2, 0, 0, 0, 0, 0, 0, 0, null, 'S2' where @oresupl2 is not null
	union all 
	select @datasus, @marca, @oresupl3, 0, 0, 0, 0, 0, 0, 0, null, 'S3' where @oresupl3 is not null
	union all 
	select @datasus, @marca, @oresupl4, 0, 0, 0, 0, 0, 0, 0, null, 'S4' where @oresupl4 is not null
	union all 
	select @datasus, @marca, @orenoapte, 0, 0, 0, 0, 0, 0, 0, null, 'NO' where @orenoapte is not null

	begin tran scriu_pontaj_zilnic
		
		update pz 
			set pz.ore=x.ore, pz.tip_ore=x.tip_ore
		from pontaj_zilnic pz
			inner join #xmlPontaj x on x.data=pz.data and x.marca=pz.marca and x.tip_ore not in ('S1','S2','S3','S4','NO')
		where pz.marca=@marca and pz.data between @datajos and @datasus and pz.tip_ore not in ('S1','S2','S3','S4','NO')

		update pz 
			set pz.ore=x.ore, pz.tip_ore=x.tip_ore
		from pontaj_zilnic pz
			inner join #xmlPontaj x on x.data=pz.data and x.marca=pz.marca and x.tip_ore=pz.tip_ore
		where pz.marca=@marca and pz.data between @datajos and @datasus and pz.tip_ore in ('S1','S2','S3','S4','NO')

		insert into pontaj_zilnic (data, marca, loc_de_munca, tip_ore, ore, detalii)
		select x.data, x.marca, @lm, x.tip_ore, x.ore, null
		from #xmlPontaj x 
		where not exists (select 1 from pontaj_zilnic pz where pz.data=x.data and pz.marca=x.marca and (x.tip_ore not in ('S1','S2','S3','S4','NO') or pz.tip_ore=x.tip_ore))
			and x.tip_ore is not null

--		raiserror ('Sa nu se scrie',11,1)

	commit tran scriu_pontaj_zilnic

end try

begin catch
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'scriu_pontaj_zilnic')
		ROLLBACK TRAN scriu_pontaj_zilnic

	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesaj, 11, 1)
end catch
