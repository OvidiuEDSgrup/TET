--***
/**	procedura pentru raportul web Pontaj zilnic	*/
Create procedure rapPontajZilnic
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
	declare @utilizator char(10), @dreptConducere int, @Colas int, @AreDreptCond int, @OSNRN int, @O100RN int, @ORegieFaraOS2 int, @listaDreptCond char(1)

	set @utilizator=dbo.fIaUtilizator(null)
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @OSNRN=dbo.iauParL('PS','OSNRN')
	set @O100RN=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	set @Colas=dbo.iauParL('SP','COLAS')
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @listaDreptCond=@cDreptCond
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0 -- daca utilizatorul nu are drept conducere atunci are acces doar la cei de tip salariat
			set @listaDreptCond='S'
	end
	
	if object_id('tempdb..#pontajPeZile') is not null drop table #pontajPeZile
	if object_id('tempdb..#pontaj') is not null drop table #pontaj

--	selectez datele de luat in calcul
	select a.data, a.marca, max(p.nume) as nume, a.Loc_de_munca as lm, max(lm.denumire) as den_lm, max(a.regim_de_lucru) as regim_de_lucru, 
		sum(a.Ore_regie+a.ore_acord
			+(case when @OSNRN=1 then (case when @ORegieFaraOS2=1 then a.Ore_suplimentare_2 else 0 end) else a.Ore_suplimentare_1+a.Ore_suplimentare_2+a.Ore_suplimentare_3+a.Ore_suplimentare_4 end)
			+(case when @O100RN=1 then 0 else a.Ore_spor_100 end)+a.Ore_concediu_de_odihna+a.Ore_concediu_medical+a.Ore_concediu_fara_salar
			+a.Ore_nemotivate+a.Ore_intrerupere_tehnologica+a.Ore+(case when @Colas=1 then a.Spor_cond_8 else 0 end)) as total_ore, 
		sum(a.ore_regie+a.ore_acord+(case when @Colas=1 then a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4 else 0 end)) as ore_lucrate, 
		sum(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4+(case when @Colas=0 then a.ore_spor_100 else 0 end)) as ore_suplimentare,
		sum(a.ore_suplimentare_1) as ore_suplimentare_1, 
		sum(a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4+(case when @Colas=0 then a.ore_spor_100 else 0 end)) as ore_suplimentare_2, 
		sum((case when @Colas=1 then a.ore_spor_100 else 0 end)) as ore_form_prof, sum(a.ore_de_noapte) as ore_de_noapte, sum(a.spor_cond_10) as ore_delegatie, 
		sum(a.ore_concediu_de_odihna) as ore_co, sum(a.ore_concediu_medical) as ore_cm, 
		sum(a.ore_nemotivate+(case when @Colas=1 then a.Ore_invoiri else 0 end)) as ore_nemotivate, 
		sum((case when @Colas=1 then a.ore_spor_100 else a.ore_invoiri end)) as ore_invoiri, 
		sum(a.ore_intrerupere_tehnologica) as ore_IT1, sum(a.ore) as ore_IT2, sum(a.ore_concediu_fara_salar) as ore_cfs, sum(a.ore_obligatii_cetatenesti) as ore_obligatii, 
		sum((case when @Colas=1 then a.Spor_cond_8 else a.Ore__cond_2 end)) as ore_intemperii_colas, 
		sum((case when @Colas=1 then a.Ore_donare_sange else a.Ore__cond_1 end)) as ore_sp_cond_1, 
		'    ' as tip_ore, 
		(case when @grupare<2 then '' else a.Loc_de_munca end) as grupare_lm, 
		(select count(distinct b.marca) from pontaj b where b.data between @dataJos and @dataSus 
			and (@marca is null or a.marca like RTRIM(@marca)+'%') 
			and (@locm is null or a.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end))) as nr_mediu_angajati,
		isnull(max(p1.Nume),'') as nume_sef_lm, isnull(max(f.Denumire),'') as functie_sef_lm
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
		and (@marca is null or a.marca like RTRIM(@marca)+'%') 
		and (@locm is null or a.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end))
		and (@tipstat is null or ip.religia=@tipstat)
		and (@grupaMunca is null or (@grupaMExcep=0 and p.grupa_de_munca=@grupaMunca or @grupaMExcep=1 and p.grupa_de_munca<>@grupaMunca)) 
		and	(@sirmarci is null or charindex(','+rtrim(ltrim(a.marca))+',',rtrim(@sirmarci))>0)
		and (@dreptConducere=0 or (@AreDreptCond=1 and (@listaDreptCond='T' or @listaDreptCond='C' and p.pensie_suplimentara=1 or @listaDreptCond='S' and p.pensie_suplimentara<>1)) 
			or (@AreDreptCond=0 and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)			
	group by a.Data, a.Marca, a.Loc_de_munca
	order by (case when @grupare=2 then a.Loc_de_munca else '' end), (case when @alfabetic=0 then a.marca else max(p.nume) end)

--	calculez ce se afiseaza la nivel de zi
	update #Pontaj set tip_ore=' '+(case when ore_co=regim_de_lucru then 'CO' when ore_cm=regim_de_lucru then 'CM' when ore_nemotivate=regim_de_lucru then 'N' 
			when ore_IT1=regim_de_lucru then 'IT1' when ore_IT2=regim_de_lucru then 'IT2' 
			when ore_form_prof=regim_de_lucru then 'FP' when ore_invoiri=regim_de_lucru then 'IN' when ore_cfs=regim_de_lucru then 'FS' 
			when ore_obligatii=regim_de_lucru then 'OB' when ore_intemperii_Colas=regim_de_lucru then 'IM' 
			when exists (select 1 from conmed cm where cm.Marca=#Pontaj.Marca and cm.Tip_diagnostic='0-' and #Pontaj.data between cm.Data_inceput and cm.Data_sfarsit) then 'IC'
			when ore_lucrate=0 then '' else CONVERT(char(3),ore_lucrate) end) 

--	mut orele de afisat de pe verticala pe orizontala (prin pivotare)
	select Marca, 
		ISNULL(ziua1,'') as ziua1, ISNULL(ziua2,'') as ziua2, ISNULL(ziua3,'') as ziua3, ISNULL(ziua4,'') as ziua4, ISNULL(ziua5,'') as ziua5, 
		ISNULL(ziua6,'') as ziua6, ISNULL(ziua7,'') as ziua7, ISNULL(ziua8,'') as ziua8, ISNULL(ziua9,'') as ziua9, ISNULL(ziua10,'') as ziua10, 
		ISNULL(ziua11,'') as ziua11, ISNULL(ziua12,'') as ziua12, ISNULL(ziua13,'') as ziua13, ISNULL(ziua14,'') as ziua14, ISNULL(ziua15,'') as ziua15, 
		ISNULL(ziua16,'') as ziua16, ISNULL(ziua17,'') as ziua17, ISNULL(ziua18,'') as ziua18, ISNULL(ziua19,'') as ziua19, ISNULL(ziua20,'') as ziua20, 
		ISNULL(ziua21,'') as ziua21, ISNULL(ziua22,'') as ziua22, ISNULL(ziua23,'') as ziua23, ISNULL(ziua24,'') as ziua24, ISNULL(ziua25,'') as ziua25,  
		ISNULL(ziua26,'') as ziua26, ISNULL(ziua27,'') as ziua27, ISNULL(ziua28,'') as ziua28, ISNULL(ziua29,'') as ziua29, ISNULL(ziua30,'') as ziua30, 
		ISNULL(ziua31,'') as ziua31
	into #pontajPeZile
	from (
		select marca, 'ziua'+convert(char(2),day(data)) as camp, isnull(tip_ore,'') as tip_ore
		from #Pontaj where data between @dataJos and @dataSus) a
			pivot (max(tip_ore) for camp in 
				([ziua1],[ziua2],[ziua3],[ziua4],[ziua5],[ziua6],[ziua7],[ziua8],[ziua9],[ziua10],
				[ziua11],[ziua12],[ziua13],[ziua14],[ziua15],[ziua16],[ziua17],[ziua18],[ziua19],[ziua20],
				[ziua21],[ziua22],[ziua23],[ziua24],[ziua25],[ziua26],[ziua27],[ziua28],[ziua29],[ziua30],[ziua31])) b

--	selectul final
	select dbo.eom(data) as data, p.marca, p.nume, max(p.lm) as lm, max(p.den_lm) as den_lm, max(p.regim_de_lucru) as regim_de_lucru, 
		MAX(z.Ziua1) as ziua1, MAX(z.Ziua2) as ziua2, MAX(z.Ziua3) as ziua3, MAX(z.ziua4) as ziua4, MAX(z.Ziua5) as ziua5, 
		MAX(z.Ziua6) as ziua6, MAX(z.Ziua7) as ziua7, MAX(z.Ziua8) as ziua8, MAX(z.Ziua9) as ziua9, MAX(z.Ziua10) as ziua10, 
		MAX(z.Ziua11) as ziua11, MAX(z.Ziua12) as ziua12, MAX(z.Ziua13) as ziua13, MAX(z.ziua14) as ziua14, MAX(z.Ziua15) as ziua15, 
		MAX(z.Ziua16) as ziua16, MAX(z.Ziua17) as ziua17, MAX(z.Ziua18) as ziua18, MAX(z.ziua19) as ziua19, MAX(z.Ziua20) as ziua20, 
		MAX(z.Ziua21) as ziua21, MAX(z.Ziua22) as ziua22, MAX(z.Ziua23) as ziua23, MAX(z.ziua24) as ziua24, MAX(z.Ziua25) as ziua25, 
		MAX(z.Ziua26) as ziua26, MAX(z.Ziua27) as ziua27, MAX(z.Ziua28) as ziua28, MAX(z.ziua29) as ziua29, MAX(z.Ziua30) as ziua30, MAX(z.Ziua31) as ziua31, 
		SUM(total_ore) as total_ore, SUM(ore_lucrate) as ore_lucrate, 
		SUM(ore_suplimentare) as ore_suplimentare, SUM(ore_suplimentare_1) as ore_suplimentare_1, SUM(ore_suplimentare_2) as ore_suplimentare_2, 
		SUM(ore_form_prof) as ore_form_prof, SUM(ore_de_noapte) as ore_de_noapte, SUM(ore_delegatie) as ore_delegatie, 
		SUM(ore_co) as ore_co, SUM(ore_cm) as ore_cm, SUM(ore_nemotivate) as ore_nemotivate, SUM(ore_invoiri) as ore_invoiri, 
		SUM(ore_IT1+ore_IT2) as ore_intr, SUM(ore_IT1) as ore_IT1, SUM(ore_IT2) as ore_IT2, SUM(ore_cfs) as ore_cfs, SUM(ore_obligatii) as ore_obligatii, 
		SUM(ore_intemperii_Colas) as ore_intemperii_Colas, SUM(ore_sp_cond_1) as ore_sp_cond_1, 
		SUM(nr_mediu_angajati) as nr_mediu_angajati, max(nume_sef_lm) as nume_sef_lm, max(functie_sef_lm) as functie_sef_lm, MAX(grupare_lm) as grupare_lm
	from #pontaj p
		left outer join #pontajPeZile z on z.Marca=p.Marca
	Group by dbo.eom(data), p.Marca, p.Nume
	Order by grupare_lm, (case when @alfabetic=0 then p.marca else nume end)

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapPontajZilnic (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapPontajZilnic '06/01/2012', '06/30/2012', null, null, 0, null, null, null, 0, null, '1', 'T', 0
*/
