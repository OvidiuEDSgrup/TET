--***
/**	procedura pentru raportul web Pontaj zilnic	pe tipuri de ore */
Create procedure rapPontajZilnicTipuriDeOre
	@dataJos datetime, @dataSus datetime, @marca char(6), @locm char(9)=null, @strict int=0, @functie char(6)=null, 
	@tipstat varchar(30)=null, @grupaMunca char(1)=null, @grupaMExcep int=0, @sirmarci varchar(1000)=null, 
	@grupare int, @cDreptCond char(1)='T', @alfabetic int=0
/*
	@grupare=1	->	Salariati
	@grupare=2	->	Locuri de munca, salariati
*/	
as
begin try
	set transaction isolation level read uncommitted
	declare @utilizator char(10), @dreptConducere int, @Colas int, @AreDreptCond int, @OSNRN int, @O100RN int, @ORegieFaraOS2 int, @listaDreptCond char(1),
	@proc_sant1 float, @proc_sant2 float, @den_os1 char(20), @den_os2 char(20),@den_os3 char(20), @den_os4 char(20), 
	@den_sp1 char(20), @den_sp2 char(20), @den_sp3 char(20), @den_sp4 char(20), @den_sp5 char(20), @den_sp6 char(20), @den_sp8 char(20), 
	@den_intr1 char(20), @den_intr2 char(20), @ordine int

	set @utilizator=dbo.fIaUtilizator(null)
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @OSNRN=dbo.iauParL('PS','OSNRN')
	set @O100RN=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	set @proc_sant1 = dbo.iauParN('PS','SPSANT1') 
	set @proc_sant2 = dbo.iauParN('PS','SPSANT2') 
	set @den_os1 = dbo.iauParA('PS','OSUPL1') 
	set @den_os2 = dbo.iauParA('PS','OSUPL2') 
	set @den_os3 = dbo.iauParA('PS','OSUPL3') 
	set @den_os4 = dbo.iauParA('PS','OSUPL4') 
	set @den_sp1 = dbo.iauParA('PS','SCOND1') 
	set @den_sp2 = dbo.iauParA('PS','SCOND2') 
	set @den_sp3 = dbo.iauParA('PS','SCOND3') 
	set @den_sp4 = dbo.iauParA('PS','SCOND4') 
	set @den_sp5 = dbo.iauParA('PS','SCOND5') 
	set @den_sp6 = dbo.iauParA('PS','SCOND6') 
	set @den_sp8 = dbo.iauParA('PS','SCOND8') 
	set @den_intr1 = dbo.iauParA('PS','PROCINT') 	
	set @den_intr2 = dbo.iauParA('PS','PROC2INT') 
	set @Colas=dbo.iauParL('SP','COLAS')
	set @ordine=0
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @listaDreptCond=@cDreptCond
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0 -- daca utilizatorul nu are drept conducere atunci are acces doar la cei de tip salariat
			set @listaDreptCond='S'
	end
	
	if object_id('tempdb..#tmpPontaj') is not null drop table #tmpPontaj
	if object_id('tempdb..#pontaj') is not null drop table #pontaj
	if object_id('tempdb..#ordine') is not null drop table #ordine

--	selectez datele de luat in calcul
	select a.data, a.marca, p.nume, a.Loc_de_munca as lm, lm.denumire as den_lm, a.regim_de_lucru, 
		convert(float, Ore_regie) Ore_regie, convert(float, Ore_acord) Ore_acord, convert(float, Ore_suplimentare_1) Ore_supl1, 
		convert(float, Ore_suplimentare_2) Ore_supl2, convert(float, Ore_suplimentare_3) Ore_supl3, 
		convert(float, Ore_suplimentare_4) Ore_supl4, convert(float, Ore_spor_100) Ore_spor_100, convert(float, Ore_de_noapte) Ore_noapte,
		convert(float, Ore_intrerupere_tehnologica) Ore_intr_tehn1, convert(float, Ore_concediu_de_odihna) ore_CO, 
		convert(float, Ore_concediu_medical) Ore_CM, convert(float, Ore_invoiri) Ore_invoiri, convert(float, Ore_nemotivate) Ore_nemotivate, 
		convert(float, Ore_obligatii_cetatenesti) Ore_obligatii, convert(float, Ore_concediu_fara_salar) Ore_CFS, 
		convert(float, a.Spor_cond_8) Spor_cond_8, convert(float, Ore_sistematic_peste_program) Ore_sist_p_prg, 
		convert(float, Ore__cond_1) Ore_cond_1, convert(float, Ore__cond_2) Ore_cond_2, convert(float, Ore__cond_3) Ore_cond_3, 
		convert(float, Ore__cond_4) Ore_cond_4, convert(float, Ore__cond_5) Ore_cond_5, convert(float, Ore__cond_6) Ore_cond_6, 
		convert(float, Ore) Ore_intr_tehn2, convert(float,a.Spor_cond_10) Ore_delegatie, convert(float,a.Spor_cond_9) Ore_detasare, 
		convert(float, (case when @Colas=0 or a.Spor_conditii_6=@proc_sant1 then Ore_donare_sange else 0 end)) Ore_cond_61,
		convert(float, (case when @Colas=1 and a.Spor_conditii_6=@proc_sant2 then Ore_donare_sange else 0 end)) Ore_cond_62,
		(case when @grupare<=2 then '' else a.Loc_de_munca end) as grupare_lm,
		isnull(p1.Nume,'') as nume_sef_lm, isnull(f.Denumire,'') as functie_sef_lm
	into #Pontaj
	from pontaj a 
		left outer join personal p on a.marca = p.marca 
		left outer join lm on a.loc_de_munca = lm.Cod
		left outer join infopers ip on a.marca=ip.marca 
		left outer join speciflm s on a.loc_de_munca = s.loc_de_munca
		left outer join personal p1 on p1.marca = s.Marca 
		left outer join functii f on p1.Cod_functie = f.Cod_functie 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.Loc_de_munca
	where a.data between @dataJos and @dataSus 
		and (@marca is null or a.marca=RTRIM(@marca)) 
		and (@locm is null or a.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end))
		and (@tipstat is null or ip.religia=@tipstat)
		and (@grupaMunca is null or (@grupaMExcep=0 and p.grupa_de_munca=@grupaMunca or @grupaMExcep=1 and p.grupa_de_munca<>@grupaMunca)) 
		and	(@sirmarci is null or charindex(','+rtrim(ltrim(a.marca))+',',rtrim(@sirmarci))>0)
		and (@dreptConducere=0 or (@AreDreptCond=1 and (@listaDreptCond='T' or @listaDreptCond='C' and p.pensie_suplimentara=1 or @listaDreptCond='S' and p.pensie_suplimentara<>1)) 
			or (@AreDreptCond=0 and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)			
	order by (case when @grupare=2 then a.Loc_de_munca else '' end), (case when @alfabetic=0 then a.marca else p.nume end)

/**	pana aici select "cinstit" cu filtrare date, cu conversie la float pe toate datele pentru a nu intampina probleme la "unpivot" */
	select data, marca, nume, lm, den_lm, tip_ore, ore, 0 as ordine, grupare_lm, nume_sef_lm, functie_sef_lm
	into #tmpPontaj
	from (
		select data, marca, nume, lm, den_lm, grupare_lm, nume_sef_lm, functie_sef_lm, Ore_regie, Ore_acord, 
			Ore_supl1, Ore_supl2, Ore_supl3, Ore_supl4, Ore_spor_100 as [Ore spor 100%], Ore_noapte, Ore_CO, Ore_CM, 
			Ore_intr_tehn1, Ore_intr_tehn2, Ore_obligatii, Ore_CFS, Ore_invoiri, Ore_nemotivate, Ore_delegatie, Ore_detasare, Spor_cond_8, 
			Ore_cond_1, Ore_cond_2, Ore_cond_3, Ore_cond_4, Ore_cond_5, Ore_cond_61, Ore_cond_62
		from #Pontaj) a
			unpivot (ore for tip_ore in 
				(Ore_regie,Ore_acord,Ore_supl1,Ore_supl2,Ore_supl3,Ore_supl4,[Ore spor 100%],Ore_noapte,
				Ore_CO,Ore_CM,Ore_intr_tehn1,Ore_intr_tehn2,Ore_obligatii,Ore_CFS,Ore_invoiri,Ore_nemotivate,
				Ore_delegatie,Ore_detasare,Spor_cond_8,Ore_cond_1,Ore_cond_2,Ore_cond_3,Ore_cond_4,Ore_cond_5,Ore_cond_61,Ore_cond_62)) b
	update #tmpPontaj set @ordine=@ordine+1, ordine=@ordine

--	pun intr-o tabela temporara, ordinea in care doresc sa afisez tipurile de ore la final
	select distinct tip_ore, MIN(ordine) as ordine, space(50) as den_ore into #ordine from #tmpPontaj group by tip_ore

--	calculez totalurile pe tipuri de ore
--	momentan scos pentru ca merge mai greu decat sa fac la final insumarea pe linie
/*
	insert into #tmpPontaj
	select '12/31/2999', marca, nume, lm, den_lm, tip_ore, SUM(ore) as ore
	from #tmpPontaj
	group by marca, nume, lm, den_lm, tip_ore
*/
--	dau coloanelor de ore denumirile configurate
	update #ordine set den_ore=(case when tip_ore='Ore_supl1' then @den_os1  when tip_ore='Ore_supl2' then @den_os2 
		when tip_ore='Ore_supl3' then @den_os3 when tip_ore='Ore_supl4' then @den_os4 
		when tip_ore='Ore_cond_1' then @den_sp1 when tip_ore='Ore_cond_2' then @den_sp2
		when tip_ore='Ore_cond_3' then @den_sp3 when tip_ore='Ore_cond_4' then @den_sp4 when tip_ore='Ore_cond_5' then @den_sp5
		when tip_ore='Ore_cond_61' then rtrim(@den_sp6)+(case when @Colas=1 then '1' else '' end) 
		when tip_ore='Ore_cond_62' then rtrim(@den_sp6)+(case when @Colas=1 then '2' else '' end) 
		when tip_ore='Spor_cond_8' then @den_sp8 
		when tip_ore='Ore_intr_tehn1' then @den_intr1 when tip_ore='Ore_intr_tehn2' then @den_intr2 
		when @Colas=1 and tip_ore='Ore spor 100%' then 'Form. prof.' else tip_ore end)

--	elimin din denumirea orelor caracterul "_"
	update #ordine set den_ore=replace(den_ore,'_',' ')

--	selectul final
	select marca, nume, lm, den_lm, o.den_ore as tip_ore, 
		ISNULL(ziua1,'') as ziua1, ISNULL(ziua2,'') as ziua2, ISNULL(ziua3,'') as ziua3, ISNULL(ziua4,'') as ziua4, ISNULL(ziua5,'') as ziua5, 
		ISNULL(ziua6,'') as ziua6, ISNULL(ziua7,'') as ziua7, ISNULL(ziua8,'') as ziua8, ISNULL(ziua9,'') as ziua9, ISNULL(ziua10,'') as ziua10, 
		ISNULL(ziua11,'') as ziua11, ISNULL(ziua12,'') as ziua12, ISNULL(ziua13,'') as ziua13, ISNULL(ziua14,'') as ziua14, ISNULL(ziua15,'') as ziua15, 
		ISNULL(ziua16,'') as ziua16, ISNULL(ziua17,'') as ziua17, ISNULL(ziua18,'') as ziua18, ISNULL(ziua19,'') as ziua19, ISNULL(ziua20,'') as ziua20, 
		ISNULL(ziua21,'') as ziua21, ISNULL(ziua22,'') as ziua22, ISNULL(ziua23,'') as ziua23, ISNULL(ziua24,'') as ziua24, ISNULL(ziua25,'') as ziua25,  
		ISNULL(ziua26,'') as ziua26, ISNULL(ziua27,'') as ziua27, ISNULL(ziua28,'') as ziua28, ISNULL(ziua29,'') as ziua29, ISNULL(ziua30,'') as ziua30, 
		ISNULL(ziua31,'') as ziua31, --[total_ore] as total_ore
		ISNULL(ziua1,'') + ISNULL(ziua2,'') + ISNULL(ziua3,'') + ISNULL(ziua4,'') + ISNULL(ziua5,'') + ISNULL(ziua6,'') 
		+ ISNULL(ziua7,'') + ISNULL(ziua8,'') + ISNULL(ziua9,'') + ISNULL(ziua10,'') + ISNULL(ziua11,'') + ISNULL(ziua12,'') 
		+ ISNULL(ziua13,'') + ISNULL(ziua14,'') + ISNULL(ziua15,'') + ISNULL(ziua16,'') + ISNULL(ziua17,'') + ISNULL(ziua18,'') 
		+ ISNULL(ziua19,'') + ISNULL(ziua20,'') + ISNULL(ziua21,'') + ISNULL(ziua22,'') + ISNULL(ziua23,'') + ISNULL(ziua24,'') 
		+ ISNULL(ziua25,'') + ISNULL(ziua26,'') + ISNULL(ziua27,'') + ISNULL(ziua28,'') + ISNULL(ziua29,'') + ISNULL(ziua30,'') + ISNULL(ziua31,'') as total_ore,
		grupare_lm, nume_sef_lm, functie_sef_lm
	from (
		select marca, nume, lm, den_lm, tip_ore, grupare_lm, nume_sef_lm, functie_sef_lm, 
			(case when YEAR(data)=2999 then 'total_ore' else 'ziua'+convert(char(2),day(data)) end) as camp, isnull(ore,'') as ore
		from #tmpPontaj where ore<>0) a
			pivot (sum(ore) for camp in 
				([ziua1],[ziua2],[ziua3],[ziua4],[ziua5],[ziua6],[ziua7],[ziua8],[ziua9],[ziua10],
				[ziua11],[ziua12],[ziua13],[ziua14],[ziua15],[ziua16],[ziua17],[ziua18],[ziua19],[ziua20],
				[ziua21],[ziua22],[ziua23],[ziua24],[ziua25],[ziua26],[ziua27],[ziua28],[ziua29],[ziua30],[ziua31],[total_ore])) b
		left outer join #ordine o on o.tip_ore=b.tip_ore
	order by (case when @grupare=2 then lm else '' end), (case when @alfabetic=0 then marca else nume end), o.ordine, b.tip_ore

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapPontajZilnicTipuriDeOre (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapPontajZilnicTipuriDeOre '06/01/2012', '06/30/2012', null, null, 0, null, null, null, 0, null, '1', 'T', 0
*/
