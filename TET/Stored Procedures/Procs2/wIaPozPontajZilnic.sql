--***
create procedure wIaPozPontajZilnic @sesiune varchar(50), @parXML xml
as
begin
	declare
		@utilizator varchar(20), @f_lm varchar(20), @f_nume varchar(100), @datalunii datetime, @datajos datetime, @datasus datetime, 
		@lm varchar(10), @xml xml, @cautare varchar(500), @tip varchar(2), @ore_luna float, @ore_luna_tura float, @ScadOS_RN int, @ScadO100_RN int, @RegimVariabil int

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select
		@tip = @parXML.value('(/row/@tip)[1]','varchar(9)'),
		@lm = @parXML.value('(/row/@lm)[1]','varchar(9)'),
		@datalunii = @parXML.value('(/row/@data)[1]','datetime'),
		@datajos = @parXML.value('(/row/@datajos)[1]','datetime'),
		@datasus = @parXML.value('(/row/@datasus)[1]','datetime'),
		@f_lm = '%' + replace(isnull(@parXML.value('(/row/@f_lm)[1]','varchar(20)'),'%'),' ','%') + '%',
		@f_nume = '%' + replace(isnull(@parXML.value('(/row/@f_nume)[1]','varchar(100)'),'%'),' ','%') + '%',
		@cautare=rtrim(ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), ''))

	if @datajos is null
		select @datajos=dbo.BOM(@datalunii), @datasus=dbo.EOM(@datalunii)

	set @ore_luna=(select val_numerica from par_lunari where Tip='PS' and parametru='ORE_LUNA' and data=@datasus)
	set @ore_luna_tura=(select val_numerica from par_lunari where Tip='PS' and parametru='ORET_LUNA' and data=@datasus)

	select	@RegimVariabil=max(case when parametru='REGIMLV' then Val_logica else 0 end),
			@ScadOS_RN=max(case when parametru='OSNRN' then Val_logica else 0 end),
			@ScadO100_RN=max(case when parametru='O100NRN' then Val_logica else 0 end)
	from par where tip_parametru in ('PS') and parametru in ('REGIMLV','OSNRN','O100NRN')

	if object_id('tempdb..#personal') is not null drop table #personal
	if object_id('tempdb..#pontaj_zilnic') is not null drop table #pontaj_zilnic
	if object_id('tempdb..#date') is not null drop table #date
	if object_id('tempdb..#dateTipOre') is not null drop table #dateTipOre
	if object_id('tempdb..#totalOre') is not null drop table #totalOre
	if object_id('tempdb..#regimlucru') is not null drop table #regimlucru

	select marca, rl into #regimlucru
	from fDate_pontaj_automat (@datajos, @datasus, @datasus, 'RL', '', 0, 0) po

	select p.*, left(rtrim(isnull(i.loc_de_munca,p.loc_de_munca)),1) as lm, 
		p.detalii.value('(/row/@lmformatie)[1]','varchar(20)') as lmformatie, isnull(e.Procent,0) as ore_lucratoare, rl.rl
	into #personal
	from personal p
		left join istpers i on i.marca=p.marca and i.data=@datasus
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
		left outer join extinfop e on e.Marca=p.Marca and e.Cod_inf='TIPINTREPTM' and e.Val_inf='OrePeLuna' and e.Procent<>0
		left join #regimlucru rl on rl.marca=p.marca
	where isnull(i.loc_de_munca,p.loc_de_munca) like rtrim(@lm)+'%'
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	update #personal set ore_lucratoare=
		(case when @RegimVariabil=1 and @ore_luna_tura<>0 and rl<>0 and rl=@ore_luna_tura then rl
		when data_angajarii_in_unitate between @datajos and @datasus or loc_ramas_vacant=1 and data_plec between @datajos and @datasus
			then dbo.zile_lucratoare((case when data_angajarii_in_unitate between @datajos and @datasus then data_angajarii_in_unitate else @datajos end),
				(case when loc_ramas_vacant=1 and data_plec between @datajos and @datasus then DateAdd(day,-1,data_plec) else @datasus end))*rl
		else @ore_luna/8*rl end)
	where ore_lucratoare=0

	select pz.*
	into #pontaj_zilnic
	from pontaj_zilnic pz
		inner join #personal p on p.marca=pz.marca
		left join lm on lm.cod=isnull(p.lmformatie,p.lm)
	where pz.data between @datajos and @datasus
		and (@cautare='' 
				or len(rtrim(@cautare))=1 and left(p.nume,1)=@cautare	-- daca @cautare este pe un caracter filtram dupa primul caracter din nume. Altfel dupa filtrarea normala.
				or len(rtrim(@cautare))>1 
			and (isnull(p.nume,'') like '%'+@cautare+'%' 
				or p.marca like @cautare+'%' or isnull(p.lmformatie,'') like '%'+@cautare+'%' 
				or isnull(lm.denumire,'') like '%'+@cautare+'%'))

	if exists (select * from sysobjects where name ='wIaPozPontajZilnicSP')
		exec wIaPozPontajZilnicSP @sesiune=@sesiune, @parXML=@parXML

	select p.lm as lm, day(pz.data) as zi, rtrim(dbo.fDenumireLuna(pz.data)) as luna, month(pz.data) as luna_num, YEAR(pz.data) as an, 
		rtrim(pz.marca) as marca, rtrim(p.nume) as nume, ore--, tip_ore
	into #date
	from #pontaj_zilnic pz
		inner join #personal p on p.marca=pz.marca
	where pz.data between @datajos and @datasus
		and pz.tip_ore not in ('S1','S2','S3','S4','NO')

	select rtrim(p.lm) as lm, day(pz.data) as zi, rtrim(dbo.fDenumireLuna(pz.data)) as luna, month(pz.data) as luna_num, YEAR(pz.data) as an, 
		rtrim(pz.marca) as marca, rtrim(p.nume) as nume, (case when tip_ore='OB' then 'EF' else tip_ore end) as tip_ore	--	de tratat pe specific
	into #dateTipOre
	from #pontaj_zilnic pz
		inner join #personal p on p.marca=pz.marca
	where pz.data between @datajos and @datasus
		and pz.tip_ore not in ('S1','S2','S3','S4','NO')

	select rtrim(dbo.fDenumireLuna(pz.data)) as luna, month(pz.data) as luna_num, YEAR(pz.data) as an, rtrim(pz.marca) as marca, 
		sum(case when pz.tip_ore in ('OL','OD') then ore else 0 end) as orelucrate, 
		sum(case when pz.tip_ore in ('S1','S2','S3','S4') then pz.ore else 0 end) as oresupl, 
		sum(case when pz.tip_ore='CO' then ore else 0 end) as oreco, sum(case when pz.tip_ore='CM' then ore else 0 end) as orecm,
		sum(case when pz.tip_ore='IN' then ore else 0 end) as oreinvoiri, sum(case when pz.tip_ore='NE' then ore else 0 end) as orenemotivate, 
		sum(case when pz.tip_ore='FS' then ore else 0 end) as orecfs, 
		sum(case when pz.tip_ore='LP' then ore else 0 end) as oreintr, sum(case when pz.tip_ore='OB' then ore else 0 end) as oreobl, max(p.ore_lucratoare) as ore_lucratoare
	into #totalOre
	from #pontaj_zilnic pz
		inner join #personal p on p.marca=pz.marca
	where pz.data between @datajos and @datasus
	group by pz.marca, rtrim(dbo.fDenumireLuna(pz.data)), month(pz.data), YEAR(pz.data)

	if object_id('tempdb..#pivot') is not null drop table #pivot
	if object_id('tempdb..#pivotTipOre') is not null drop table #pivotTipOre

	select
		lm, luna_num, luna, an, marca , nume, 
		isnull(convert(int,[1]) ,0) as ziua1, 
		isnull(convert(int,[2]) ,0) as ziua2, 
		isnull(convert(int,[3]) ,0) as ziua3, 
		isnull(convert(int,[4]) ,0) as ziua4, 
		isnull(convert(int,[5]) ,0) as ziua5, 
		isnull(convert(int,[6]) ,0) as ziua6, 
		isnull(convert(int,[7]) ,0) as ziua7, 
		isnull(convert(int,[8]) ,0) as ziua8, 
		isnull(convert(int,[9]) ,0) as ziua9, 
		isnull(convert(int,[10]),0) as ziua10, 
		isnull(convert(int,[11]),0) as ziua11, 
		isnull(convert(int,[12]),0) as ziua12, 
		isnull(convert(int,[13]),0) as ziua13, 
		isnull(convert(int,[14]),0) as ziua14, 
		isnull(convert(int,[15]),0) as ziua15, 
		isnull(convert(int,[16]),0) as ziua16, 
		isnull(convert(int,[17]),0) as ziua17, 
		isnull(convert(int,[18]),0) as ziua18, 
		isnull(convert(int,[19]),0) as ziua19, 
		isnull(convert(int,[20]),0) as ziua20, 
		isnull(convert(int,[21]),0) as ziua21, 
		isnull(convert(int,[22]),0) as ziua22, 
		isnull(convert(int,[23]),0) as ziua23, 
		isnull(convert(int,[24]),0) as ziua24, 
		isnull(convert(int,[25]),0) as ziua25, 
		isnull(convert(int,[26]),0) as ziua26, 
		isnull(convert(int,[27]),0) as ziua27, 
		isnull(convert(int,[28]),0) as ziua28, 
		isnull(convert(int,[29]),0) as ziua29, 
		isnull(convert(int,[30]),0) as ziua30, 
		isnull(convert(int,[31]),0) as ziua31
	into #pivot
	from #date
	pivot
	(
	sum(ore)
	for zi in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30], [31])
	) as piv


	select
		lm, luna_num, luna, an, marca , nume, 
		isnull(convert(varchar(2),[1]) ,0) as tipziua1, 
		isnull(convert(varchar(2),[2]) ,0) as tipziua2, 
		isnull(convert(varchar(2),[3]) ,0) as tipziua3, 
		isnull(convert(varchar(2),[4]) ,0) as tipziua4, 
		isnull(convert(varchar(2),[5]) ,0) as tipziua5, 
		isnull(convert(varchar(2),[6]) ,0) as tipziua6, 
		isnull(convert(varchar(2),[7]) ,0) as tipziua7, 
		isnull(convert(varchar(2),[8]) ,0) as tipziua8, 
		isnull(convert(varchar(2),[9]) ,0) as tipziua9, 
		isnull(convert(varchar(2),[10]),0) as tipziua10, 
		isnull(convert(varchar(2),[11]),0) as tipziua11, 
		isnull(convert(varchar(2),[12]),0) as tipziua12, 
		isnull(convert(varchar(2),[13]),0) as tipziua13, 
		isnull(convert(varchar(2),[14]),0) as tipziua14, 
		isnull(convert(varchar(2),[15]),0) as tipziua15, 
		isnull(convert(varchar(2),[16]),0) as tipziua16, 
		isnull(convert(varchar(2),[17]),0) as tipziua17, 
		isnull(convert(varchar(2),[18]),0) as tipziua18, 
		isnull(convert(varchar(2),[19]),0) as tipziua19, 
		isnull(convert(varchar(2),[20]),0) as tipziua20, 
		isnull(convert(varchar(2),[21]),0) as tipziua21, 
		isnull(convert(varchar(2),[22]),0) as tipziua22, 
		isnull(convert(varchar(2),[23]),0) as tipziua23, 
		isnull(convert(varchar(2),[24]),0) as tipziua24, 
		isnull(convert(varchar(2),[25]),0) as tipziua25, 
		isnull(convert(varchar(2),[26]),0) as tipziua26, 
		isnull(convert(varchar(2),[27]),0) as tipziua27, 
		isnull(convert(varchar(2),[28]),0) as tipziua28, 
		isnull(convert(varchar(2),[29]),0) as tipziua29, 
		isnull(convert(varchar(2),[30]),0) as tipziua30, 
		isnull(convert(varchar(2),[31]),0) as tipziua31
	into #pivotTipOre
	from #dateTipOre
	pivot
	(
	max(tip_ore)
	for zi in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30], [31])
	) as piv
/*
	select * from #pivot
	select * from #pivotTipOre
	select * from #totalOre where marca='D1101'
*/
	select @xml = 
	(select 
		@tip as tip, @tip as subtip,  max(isnull(rtrim(l.denumire),'< necompletat >')) as marca, max(d.luna) + ' ' + convert(varchar(4),d.an) as densalariat,
		sum(ziua1) as ziua1, sum(ziua2) as ziua2, sum(ziua3) as ziua3, sum(ziua4) as ziua4, sum(ziua5) as ziua5, sum(ziua6) as ziua6, sum(ziua7) as ziua7, sum(ziua8) as ziua8,
		sum(ziua9) as ziua9, sum(ziua10) as ziua10, sum(ziua11) as ziua11, sum(ziua12) as ziua12, sum(ziua13) as ziua13, sum(ziua14) as ziua14, sum(ziua15) as ziua15, sum(ziua16) as ziua16,
		sum(ziua17) as ziua17, sum(ziua18) as ziua18, sum(ziua19) as ziua19, sum(ziua20) as ziua20, sum(ziua21) as ziua21, sum(ziua22) as ziua22, sum(ziua23) as ziua23, sum(ziua24) as ziua24,
		sum(ziua25) as ziua25, sum(ziua26) as ziua26, sum(ziua27) as ziua27, sum(ziua28) as ziua28, sum(ziua29) as ziua29, sum(ziua30) as ziua30, sum(ziua31) as ziua31,
		(select @tip as tip, @tip as subtip,  
			p.marca as marca, max(p.nume) as densalariat,
			(case when sum(ziua1)=0 then '' when max(pt.tipziua1) not in ('OL','OD') then max(pt.tipziua1) else convert(varchar(2),sum(ziua1)) end) as ziua1,
			(case when sum(ziua2)=0 then '' when max(pt.tipziua2) not in ('OL','OD') then max(pt.tipziua2) else convert(varchar(2),sum(ziua2)) end) as ziua2,
			(case when sum(ziua3)=0 then '' when max(pt.tipziua3) not in ('OL','OD') then max(pt.tipziua3) else convert(varchar(2),sum(ziua3)) end) as ziua3,
			(case when sum(ziua4)=0 then '' when max(pt.tipziua4) not in ('OL','OD') then max(pt.tipziua4) else convert(varchar(2),sum(ziua4)) end) as ziua4,
			(case when sum(ziua5)=0 then '' when max(pt.tipziua5) not in ('OL','OD') then max(pt.tipziua5) else convert(varchar(2),sum(ziua5)) end) as ziua5,
			(case when sum(ziua6)=0 then '' when max(pt.tipziua6) not in ('OL','OD') then max(pt.tipziua6) else convert(varchar(2),sum(ziua6)) end) as ziua6,
			(case when sum(ziua7)=0 then '' when max(pt.tipziua7) not in ('OL','OD') then max(pt.tipziua7) else convert(varchar(2),sum(ziua7)) end) as ziua7,
			(case when sum(ziua8)=0 then '' when max(pt.tipziua8) not in ('OL','OD') then max(pt.tipziua8) else convert(varchar(2),sum(ziua8)) end) as ziua8,
			(case when sum(ziua9)=0 then '' when max(pt.tipziua9) not in ('OL','OD') then max(pt.tipziua9) else convert(varchar(2),sum(ziua9)) end) as ziua9,
			(case when sum(ziua10)=0 then '' when max(pt.tipziua10) not in ('OL','OD') then max(pt.tipziua10) else convert(varchar(2),sum(ziua10)) end) as ziua10,
			(case when sum(ziua11)=0 then '' when max(pt.tipziua11) not in ('OL','OD') then max(pt.tipziua11) else convert(varchar(2),sum(ziua11)) end) as ziua11,
			(case when sum(ziua12)=0 then '' when max(pt.tipziua12) not in ('OL','OD') then max(pt.tipziua12) else convert(varchar(2),sum(ziua12)) end) as ziua12,
			(case when sum(ziua13)=0 then '' when max(pt.tipziua13) not in ('OL','OD') then max(pt.tipziua13) else convert(varchar(2),sum(ziua13)) end) as ziua13,
			(case when sum(ziua14)=0 then '' when max(pt.tipziua14) not in ('OL','OD') then max(pt.tipziua14) else convert(varchar(2),sum(ziua14)) end) as ziua14,
			(case when sum(ziua15)=0 then '' when max(pt.tipziua15) not in ('OL','OD') then max(pt.tipziua15) else convert(varchar(2),sum(ziua15)) end) as ziua15,
			(case when sum(ziua16)=0 then '' when max(pt.tipziua16) not in ('OL','OD') then max(pt.tipziua16) else convert(varchar(2),sum(ziua16)) end) as ziua16,
			(case when sum(ziua17)=0 then '' when max(pt.tipziua17) not in ('OL','OD') then max(pt.tipziua17) else convert(varchar(2),sum(ziua17)) end) as ziua17,
			(case when sum(ziua18)=0 then '' when max(pt.tipziua18) not in ('OL','OD') then max(pt.tipziua18) else convert(varchar(2),sum(ziua18)) end) as ziua18,
			(case when sum(ziua19)=0 then '' when max(pt.tipziua19) not in ('OL','OD') then max(pt.tipziua19) else convert(varchar(2),sum(ziua19)) end) as ziua19,
			(case when sum(ziua20)=0 then '' when max(pt.tipziua20) not in ('OL','OD') then max(pt.tipziua20) else convert(varchar(2),sum(ziua20)) end) as ziua20,
			(case when sum(ziua21)=0 then '' when max(pt.tipziua21) not in ('OL','OD') then max(pt.tipziua21) else convert(varchar(2),sum(ziua21)) end) as ziua21,
			(case when sum(ziua22)=0 then '' when max(pt.tipziua22) not in ('OL','OD') then max(pt.tipziua22) else convert(varchar(2),sum(ziua22)) end) as ziua22,
			(case when sum(ziua23)=0 then '' when max(pt.tipziua23) not in ('OL','OD') then max(pt.tipziua23) else convert(varchar(2),sum(ziua23)) end) as ziua23,
			(case when sum(ziua24)=0 then '' when max(pt.tipziua24) not in ('OL','OD') then max(pt.tipziua24) else convert(varchar(2),sum(ziua24)) end) as ziua24,
			(case when sum(ziua25)=0 then '' when max(pt.tipziua25) not in ('OL','OD') then max(pt.tipziua25) else convert(varchar(2),sum(ziua25)) end) as ziua25,
			(case when sum(ziua26)=0 then '' when max(pt.tipziua26) not in ('OL','OD') then max(pt.tipziua26) else convert(varchar(2),sum(ziua26)) end) as ziua26,
			(case when sum(ziua27)=0 then '' when max(pt.tipziua27) not in ('OL','OD') then max(pt.tipziua27) else convert(varchar(2),sum(ziua27)) end) as ziua27,
			(case when sum(ziua28)=0 then '' when max(pt.tipziua28) not in ('OL','OD') then max(pt.tipziua28) else convert(varchar(2),sum(ziua28)) end) as ziua28,
			(case when sum(ziua29)=0 then '' when max(pt.tipziua29) not in ('OL','OD') then max(pt.tipziua29) else convert(varchar(2),sum(ziua29)) end) as ziua29,
			(case when sum(ziua30)=0 then '' when max(pt.tipziua30) not in ('OL','OD') then max(pt.tipziua30) else convert(varchar(2),sum(ziua30)) end) as ziua30,
			(case when sum(ziua31)=0 then '' when max(pt.tipziua31) not in ('OL','OD') then max(pt.tipziua31) else convert(varchar(2),sum(ziua31)) end) as ziua31,
			max(t.orelucrate) as orelucrate, max(t.oresupl) as oresupl, max(t.orecm) as orecm, max(t.oreco) as oreco, 
			max(t.orenemotivate) as orenemotivate, max(t.oreinvoiri) as oreinvoiri, max(t.orecfs) as orecfs, max(t.oreintr) as oreintr, max(t.oreobl) as oreobl, 
			(case when max(t.orelucrate)-(case when @ScadOS_RN=1 then max(t.oresupl)else 0 end)
				+max(t.orecm)+max(t.oreco)+max(t.orenemotivate)+max(t.oreinvoiri)+max(t.orecfs)+max(t.oreintr)+max(t.oreobl)<>max(t.ore_lucratoare) then '#FF0000' else '#000000' end) as culoare
		from #pivot p
		left outer join #pivotTipOre pt on pt.marca=p.marca and pt.luna_num=p.luna_num and pt.an=p.an 
		left outer join #totalOre t on t.marca=p.marca
		where p.lm=d.lm and p.luna_num=d.luna_num and p.an=d.an and p.nume like @f_nume
		group by p.luna_num, p.an, p.marca
		order by max(p.nume)
		for xml raw, type)
	from #pivot d
	LEFT join lm l on l.cod=d.lm
	where l.denumire like @f_lm
	group by d.lm, d.an, d.luna_num
	order by an desc, luna_num desc, lm
	for xml raw, root('Ierarhie'))

	if @xml is not null
		set @xml.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

	select @xml for xml path('Date')
end
