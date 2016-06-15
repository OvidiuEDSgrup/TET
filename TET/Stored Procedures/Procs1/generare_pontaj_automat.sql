--***
/**	proc. generare pontaj automat	*/
Create procedure generare_pontaj_automat
	@dataJ datetime, @dataS datetime, @pMarca char(6)='', @pLocm char(9)='', @pTipStat char(100)='', @pGrupaMExcep char(1)='', 
	@pPontajOresS int=0, @pOresS char(1)='', @pPontajOresD int=0, @pOresD char(1)='', @lStergPontaj int=0, @lGenerezPontaj int=1
As
set transaction isolation level read uncommitted
declare @utilizator varchar(10), @DataIncr datetime, @InstPubl int, @lPontajZilnic int, 
	@nNrTichete float, @lGestionareTichete int, @lTicheteMacheta int, @lTicheteMarca int, @lTicheteZL int, @lZileFaraTicheteAng int, @nZileFaraTichete int, @lTicheteZLDim int, @lTicheteRL int, 
	@SOreCOPontaj int, @SOreCMPontaj int, @Ssalcatl int, @RegimLV int, @SalPeComenzi int, @PlataCuOra int, @ScadOSORN int, @Spc_ORN int, @COMacheta int, @COEVMacheta int, 
	@ProcIT1 float, @ProcIT2 float, @ProcIT3 float, @IT1SuspContr int, @IT2SuspContr int, @IT3SuspContr int, @denIntrTehn3 varchar(30), @Dafora int, 
	@nAnulInchis int, @nLunaInchisa int, @DataInchisa datetime, @OreLuna float, @NrmLuna float, @dataJos datetime, @dataSus datetime, 
	@PontajW int, @PontajS int, @PontajD int, @Luna int, @Anul int, @CampOreITptOreSusp int

set @utilizator = dbo.fIaUtilizator(null) -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
set @nAnulInchis=dbo.iauParN('PS','ANUL-INCH')
set @nLunaInchisa=dbo.iauParN('PS','LUNA-INCH')
set @DataInchisa=dbo.eom(convert(datetime,convert(char(2),@nLunaInchisa)+'/01/'+convert(char(4),@nAnulInchis)))

IF @Utilizator IS NULL or @nLunaInchisa not between 1 and 12 or @nAnulInchis<=1901
	RETURN -1
set @DataInchisa=dbo.eom(convert(datetime,str(@nLunaInchisa,2)+'/01/'+str(@nAnulInchis,4)))
--	verific luna inchisa
IF @dataS<=@DataInchisa
Begin
	raiserror('(generare_pontaj_automat) Luna pe care doriti sa efectuati generare pontaj automat este inchisa!' ,16,1)
	RETURN -1
End	

set @InstPubl=dbo.iauParL('PS','INSTPUBL')
set @RegimLV=dbo.iauParL('PS','REGIMLV')
set @SalPeComenzi=dbo.iauParL('PS','SALCOM')
set @PlataCuOra=dbo.iauParL('PS','SALOR-REG')
set @lPontajZilnic=dbo.iauParL('PS','PONTZILN')
set @nNrTichete=dbo.iauParLN(dbo.eom(@DataS),'PS','NRTICHETE')
set @lGestionareTichete=dbo.iauParL('PS','TICHETE')
set @lTicheteMacheta=dbo.iauParL('PS','OPTICHINM')
set @lTicheteZL=dbo.iauParL('PS','TICHZLUC')
set @lTicheteRL=dbo.iauParL('PS','TICH-RLTP')
set @lTicheteZLDim=dbo.iauParL('PS','TICHZLDIM')
set @lTicheteMarca=dbo.iauParL('PS','TICHMARCA')
set @lZileFaraTicheteAng=dbo.iauParL('PS','TICNUZANG')
set @nZileFaraTichete=dbo.iauParN('PS','TICNUZANG')-1
set @ScadOSORN=dbo.iauParL('PS','OSNRN')
set @Spc_ORN=dbo.iauParL('PS','SP-C-ORN')
set @COMacheta=dbo.iauParL('PS','OPZILECOM')
set @COEVMacheta=dbo.iauParL('PS','COEVMCO')
set @SOreCOPontaj=dbo.iauParL('PS','SORECOPJ')
set @SOreCMPontaj=dbo.iauParL('PS','SORECMPJ')
set @Ssalcatl=dbo.iauParL('PS','CSALCATL')
set @ProcIT1=dbo.iauParN('PS','PROCINT')
set @ProcIT2=dbo.iauParN('PS','PROC2INT')
set @ProcIT3=dbo.iauParN('PS','PROC3INT')	
set @IT1SuspContr=dbo.iauParL('PS','IT1-SUSPC')
set @IT2SuspContr=dbo.iauParL('PS','PROC2INT')
set @IT3SuspContr=dbo.iauParL('PS','PROC3INT')
set @denIntrTehn3=dbo.iauParA('PS','PROC3INT')
set @Dafora=dbo.iauParL('SP','DAFORA')
set @OreLuna=dbo.iauParLN(dbo.eom(@dataS),'PS','ORE_LUNA')
set @NrmLuna=dbo.iauParLN(dbo.eom(@dataS),'PS','NRMEDOL')
select @Luna=month(@dataS), @Anul=year(@dataS)
-- stabilesc campul de ore intrerupere tehnologica (1,2 sau 3) pe care s-ar putea prelua perioadele de suspendare neplatite (operate in macheta salariati)
set @CampOreITptOreSusp=(case when @ProcIT1=0 and @IT1SuspContr=1 then 1 when @ProcIT2=0 and @IT2SuspContr=1 then 2 when @ProcIT3=0 and @IT3SuspContr=1 and @denIntrTehn3<>'' then 3 else 0 end)

if exists(select * from sysobjects where name='GenPontajSP1' and type='P') 
	exec GenPontajSP1 @dataJ, @dataS, @pMarca, @pLocm

if exists(select * from sysobjects where name='GenerareConcediiDinSuspendari' and type='P') 
	exec GenerareConcediiDinSuspendari @dataJ, @dataS, @pMarca, @pLocm, @lStergPontaj, @lGenerezPontaj

if @lStergPontaj=1
Begin
--	sterg din realcom daca se lucreaza cu [X]Incadrare salariati pe comenzi
	If @SalPeComenzi=1 
		delete realcom from realcom a 	
			left outer join infopers i on a.marca=i.marca
			left outer join personal p on a.marca=p.marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
			, pontaj b 
		where a.data between @dataJ and @dataS 
			and (@pMarca='' or a.marca=@pMarca) and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%') and a.marca=b.marca 
			and a.loc_de_munca=b.loc_de_munca and a.data=b.data and a.Numar_document='PS'+rtrim(convert(char(10),b.Numar_curent)) 		
			and (@pTipStat='' or i.Religia=@pTipStat)
			and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

--	sterg pontaj
	delete pontaj from pontaj a
		left outer join infopers i on a.marca=i.marca
		left outer join personal p on a.marca=p.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
	where a.data between @dataJ and @dataS 
		and (@pMarca='' or a.marca=@pMarca) and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%')  
		and (@pTipStat='' or i.Religia=@pTipStat)
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
End
if object_id('tempdb..#pontaj_automat') is not null drop table #pontaj_automat
Create table dbo.#pontaj_automat (Data datetime not null, Marca char(6) not null, Numar_curent smallint not null, Loc_de_munca char(9) not null, 
	Loc_munca_pentru_stat_de_plata bit not null, Tip_salarizare char(1) not null, Regim_de_lucru float not null,
	Salar_orar float not null, Ore_lucrate smallint not null, Ore_regie smallint not null, Ore_acord smallint not null, 
	Ore_suplimentare_1 smallint not null, Ore_suplimentare_2 smallint not null, Ore_suplimentare_3 smallint not null, 
	Ore_suplimentare_4 smallint not null, Ore_spor_100 smallint not null, Ore_de_noapte smallint not null, 
	Ore_intrerupere_tehnologica smallint not null, Ore_concediu_de_odihna smallint not null, Ore_concediu_medical smallint not null, 
	Ore_invoiri smallint not null, Ore_nemotivate smallint not null, Ore_obligatii_cetatenesti smallint not null, 
	Ore_concediu_fara_salar smallint not null, Ore_donare_sange smallint not null, Salar_categoria_lucrarii real not null, 
	Coeficient_acord float not null, Realizat float not null, Coeficient_de_timp float not null, Ore_realizate_acord real not null,
	Sistematic_peste_program real not null, Ore_sistematic_peste_program smallint not null, Spor_specific float not null, 
	Spor_conditii_1 float not null, Spor_conditii_2 float not null, Spor_conditii_3 float not null, Spor_conditii_4 float not null, 
	Spor_conditii_5 float not null, Spor_conditii_6 float not null, Ore__cond_1 smallint not null, Ore__cond_2 smallint not null,
	Ore__cond_3 smallint not null,Ore__cond_4 smallint not null, Ore__cond_5 smallint not null, Ore__cond_6 real not null, 
	Grupa_de_munca char(1) not null, Ore smallint not null, Spor_cond_7 float not null DEFAULT (0), Spor_cond_8 float not null, 
	Spor_cond_9 float not null, Spor_cond_10 float not null) ON [PRIMARY]

Create Unique Clustered Index [Principal] ON dbo.#pontaj_automat (Data Asc, Marca Asc, Numar_curent Asc)

set @DataIncr = (case when @lPontajZilnic=1 then @dataJ else @dataS end)
while @lGenerezPontaj=1 and @dataS >= @DataIncr 
Begin
	set @dataJos=(case when @lPontajZilnic=1 then @DataIncr else @dataJ end)
	set @dataSus=(case when @lPontajZilnic=1 then @DataIncr else @dataS end)
	set @PontajS=(case when @pPontajOresS=1 and datename(WeekDay, @DataIncr)='Saturday' then 1 else 0 end)
	set @PontajD=(case when @pPontajOresD=1 and datename(WeekDay, @DataIncr)='Sunday' then 1 else 0 end)
	set @PontajW=(case when @PontajS=1 or @PontajD=1 then 1 else 0 end)
	if (datename(WeekDay, @DataIncr) not in ('Sunday','Saturday') and @DataIncr not in (select data from calendar) and @lPontajZilnic=1 or @lPontajZilnic=1 and @PontajS=1 or @lPontajZilnic=1 and @PontajD=1 or @lPontajZilnic=0)
	Begin
		delete from #pontaj_automat
		insert into #pontaj_automat

		select @DataIncr, a.marca, 
		(case when @lPontajZilnic=1 
			then isnull((select top 1 j.numar_curent from pontaj j where j.data between @dataJ and @dataS and j.marca=a.Marca order by Numar_curent desc),0)+1 
			else 1 end), 
		a.Loc_de_munca, 1, a.Tip_salarizare, p.RL, 
		a.Salar_de_incadrare/(case when @RegimLV=1 and a.Salar_lunar_de_baza<>0 
			then a.Salar_lunar_de_baza*(case when a.Tip_salarizare in ('1','2') then @OreLuna else @NrmLuna end) 
			else (case when a.Tip_salarizare in ('1','2') then @OreLuna else @NrmLuna end)*(case when @RegimLV=0 then p.RL/8 else 1 end) end), 0 as OL, 
		round((case when a.Tip_salarizare in ('1','3','6') 
			then (case when @lPontajZilnic=1 
				then (case when @PontajW=1 
					then (case when @ScadOSORN=1 and isnull(cm.Zile,0)=0 and isnull(co.Zile,0)=0 and isnull(fs.Zile,0)=0 and isnull(iv.Zile,0)=0 and isnull(n.Zile,0)=0 
						and isnull(o.Zile,0)=0 and isnull(cd.Zile,0)=0 and isnull(r.Zile,0)=0 and isnull(fp.Zile,0)=0 and isnull(dt.Zile,0)=0 and isnull(sc.Zile,0)=0 then p.RL else 0 end) 
					else p.RL end) 
				else (p.Zile-isnull(cd.Zile,0)-isnull(r.Zile,0)-isnull(fp.Zile,0)-isnull(dt.Zile,0)-isnull(sc.Zile,0))*p.RL end) 
			else 0 end),0) as OReg, 
		round((case when a.Tip_salarizare in ('2','4','5','7') 
			then (case when @lPontajZilnic=1 
				then (case when @PontajW=1 
					then (case when @ScadOSORN=1 and isnull(cm.Zile,0)=0 and isnull(co.Zile,0)=0 and isnull(fs.Zile,0)=0 and isnull(iv.Zile,0)=0 and isnull(n.Zile,0)=0 
						and isnull(o.Zile,0)=0 and isnull(cd.Zile,0)=0 and isnull(r.Zile,0)=0 and isnull(fp.Zile,0)=0 and isnull(dt.Zile,0)=0 and isnull(sc.Zile,0)=0 then p.RL else 0 end) 
					else p.RL end) 
				else (p.Zile-isnull(cd.Zile,0)-isnull(r.Zile,0)-isnull(fp.Zile,0)-isnull(dt.Zile,0)-isnull(sc.Zile,0))*p.RL end) 
			else 0 end),0) as OAc, 
		(case when (@PontajS=1 and @pOresS='1' or @PontajD=1 and @pOresD='1') and isnull(cm.Zile,0)=0 
			and isnull(co.Zile,0)=0 and isnull(fs.Zile,0)=0 and isnull(iv.Zile,0)=0 and isnull(n.Zile,0)=0 and isnull(o.Zile,0)=0 
			and isnull(cd.Zile,0)=0 and isnull(r.Zile,0)=0 and isnull(fp.Zile,0)=0 and isnull(dt.Zile,0)=0 and isnull(sc.Zile,0)=0 then p.RL else isnull(s1.Ore,0) end) as OS1, 
		(case when (@PontajS=1 and @pOresS='2' or @PontajD=1 and @pOresD='2') and isnull(cm.Zile,0)=0 
			and isnull(co.Zile,0)=0 and isnull(fs.Zile,0)=0 and isnull(iv.Zile,0)=0 and isnull(n.Zile,0)=0 and isnull(o.Zile,0)=0 
			and isnull(cd.Zile,0)=0 and isnull(r.Zile,0)=0 and isnull(fp.Zile,0)=0 and isnull(dt.Zile,0)=0 and isnull(sc.Zile,0)=0 then p.RL else isnull(s2.Ore,0) end) as OS2, 
		(case when (@PontajS=1 and @pOresS='3' or @PontajD=1 and @pOresD='3') and isnull(cm.Zile,0)=0 
			and isnull(co.Zile,0)=0 and isnull(fs.Zile,0)=0 and isnull(iv.Zile,0)=0 and isnull(n.Zile,0)=0 and isnull(o.Zile,0)=0 
			and isnull(cd.Zile,0)=0 and isnull(r.Zile,0)=0 and isnull(fp.Zile,0)=0 and isnull(dt.Zile,0)=0 and isnull(sc.Zile,0)=0 then p.RL else isnull(s3.Ore,0) end) as OS3, 
		(case when (@PontajS=1 and @pOresS='4' or @PontajD=1 and @pOresD='4') and isnull(cm.Zile,0)=0 
			and isnull(co.Zile,0)=0 and isnull(fs.Zile,0)=0 and isnull(iv.Zile,0)=0 and isnull(n.Zile,0)=0 and isnull(o.Zile,0)=0 
			and isnull(cd.Zile,0)=0 and isnull(r.Zile,0)=0 and isnull(fp.Zile,0)=0 and isnull(dt.Zile,0)=0 and isnull(sc.Zile,0)=0 then p.RL else isnull(s4.Ore,0) end) as OS4, 
		isnull(sp.Ore,0) as O100, isnull(ono.Ore,0) as Ore_noapte, 
		isnull(r.Zile,0)*p.RL+(case when @CampOreITptOreSusp=1 then isnull(sc.Zile,0)*p.RL else 0 end) as OreIT, (case when @PontajW=1 then 0 else isnull(co.Zile,0)*p.RL end) as CO, 
		(case when @PontajW=1 then 0 else isnull(cm.Zile,0)*p.RL end) as CM, 
		(case when @PontajW=1 then 0 else isnull(iv.Zile,0)*p.RL+isnull(iv.Ore,0) end) as Inv, 
		(case when @PontajW=1 then 0 else isnull(n.Zile,0)*p.RL+isnull(n.Ore,0) end) as Nem, 
		(case when @PontajW=1 then 0 else isnull(o.Zile,0)*p.RL end) as Obl, 
		(case when @PontajW=1 then 0 else round(isnull(fs.Zile,0)*p.RL,0) end) as Cfs, 0 as DS, 
		(case when @Ssalcatl=1 and a.Tip_salarizare in ('6','7') 
			then (case when isnull((select top 1 Procent from extinfop e where e.Marca=p.Marca and e.Cod_inf='SALARORAR' and e.Data_inf<=@dataS and e.Procent<>0 order by Data_inf desc),0)<>0 
				then isnull((select top 1 Procent from extinfop e where e.Marca=p.Marca and e.Cod_inf='SALARORAR' and e.Data_inf<=@dataS and e.Procent<>0 order by Data_inf desc),0) 
				else round(a.Salar_de_incadrare/@NrmLuna,3) end) 
			else 0 end), 0 as CoefA,
		0 as Realizat, (case when p.RL>0 and p.RL<1 then p.Zile-isnull(co.Zile,0)-isnull(cm.Zile,0)-isnull(iv.Zile,0)-isnull(n.Zile,0)-isnull(o.Zile,0)-isnull(fs.Zile,0)-isnull(cd.Zile,0)
			-isnull(r.Zile,0)-isnull(fp.Zile,0)-isnull(sc.Zile,0) else 0 end) as CoefT, 0 as ORA, 
		a.Spor_sistematic_peste_program as SPS, 0 as OSPS, a.Spor_specific, a.Spor_conditii_1, a.Spor_conditii_2, a.Spor_conditii_3, a.Spor_conditii_4, a.Spor_conditii_5, a.Spor_conditii_6, 
		0 as OSp1, 0 as OSp2, 0 as OSp3, 0 as OSp4, 0 as OSp5, 0 as Tich, 
		(case when a.Grupa_de_munca in ('C','P') then 'N' else a.Grupa_de_munca end), isnull(fp.Zile,0)*p.RL+(case when @CampOreITptOreSusp=2 then isnull(sc.Zile,0)*p.RL else 0 end) as OreIT2, 
		isnull(i.Spor_cond_7,0), isnull(i.Spor_cond_8,0)+(case when @CampOreITptOreSusp=3 then isnull(sc.Zile,0)*p.RL else 0 end), 
		(case when @PontajW=1 then 0 else isnull(dt.Zile,0)*p.RL end), --isnull(i.Spor_cond_9,0)
		(case when @PontajW=1 then 0 else isnull(dl.Zile,0)*p.RL end) as Sp10
		from personal a 
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'RL', '', 0, 0) p on a.Marca=p.Marca
			left outer join infopers i on a.Marca=i.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'CM', '', 0, 0) cm on a.Marca=cm.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'CO', '', 0, 0) co on @COMacheta=1 and a.Marca=co.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'IC', '', 0, 0) cm1 on a.Marca=cm1.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'FS', '', 0, 0) fs on a.Marca=fs.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'IV', '', 0, 0) iv on a.Marca=iv.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'NE', '', 0, 0) n on a.Marca=n.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'DL', '', 0, 0) dl on a.Marca=dl.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'CD', '', 0, 0) cd on a.Marca=cd.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'S1', '', 0, 0) s1 on a.Marca=s1.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'S2', '', 0, 0) s2 on a.Marca=s2.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'S3', '', 0, 0) s3 on a.Marca=s3.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'S4', '', 0, 0) s4 on a.Marca=s4.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'SP', '', 0, 0) sp on a.Marca=sp.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'NO', '', 0, 0) ono on a.Marca=ono.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'OB', '', 0, 0) o on @COEVMacheta=1 and a.Marca=o.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'RE', '', 0, 0) r on @InstPubl=1 and a.Marca=r.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'FP', '', 0, 0) fp on @InstPubl=1 and a.Marca=fp.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'DT', '', 0, 0) dt on a.Marca=dt.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJ, @dataS, @DataIncr, 'SC', '', 0, 0) sc on a.Marca=sc.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.Loc_de_munca 
		where (@pmarca='' or a.marca=@pmarca) and (@pLocm='' or a.Loc_de_munca like rtrim(@pLocm)+'%')
			and (@pTipStat='' or i.Religia=@pTipStat) and dbo.eom(@dataJ)>=a.Data_angajarii_in_unitate
			and (@pGrupaMExcep='' or a.Grupa_de_munca<>@pGrupaMExcep)
			and (a.loc_ramas_vacant=0 or a.Data_plec>=dbo.bom(@dataJ)+1)
			and a.marca not in (select marca from pontaj j where data between @dataJos and @dataSus and j.Marca=a.Marca)
			and (@lPontajZilnic=0 or @DataIncr>=a.Data_angajarii_in_unitate and (a.Loc_ramas_vacant=0 or @DataIncr<=DateAdd(day,-1,a.Data_plec)))
			and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

		if exists(select * from sysobjects where name='GenPontajSP2' and type='P') 
			exec GenPontajSP2 @dataJ, @dataS, @pMarca, @pLocm, @DataIncr

		--exec dbo.scriu_pontaj_si_realcom @dataJ, @dataS, @DataIncr, @PontajW

		update #pontaj_automat set 
		Ore_regie=(case when a.Tip_salarizare in ('1','3') and a.Ore_regie>0 
			then a.Ore_regie*(case when @RegimLV=1 and p.Salar_lunar_de_baza<>0 
					then (case when p.Grupa_de_munca='C' then a.Regim_de_lucru/8 else p.Salar_lunar_de_baza/(case when a.Tip_salarizare='1' then @OreLuna else @NrmLuna end) end) 
					else 1 end)
				-a.Ore_concediu_medical-(case when @COMacheta=1 then a.Ore_concediu_de_odihna else 0 end)-a.Ore_invoiri-a.Ore_nemotivate-a.Ore_concediu_fara_salar
				-(case when @InstPubl=1 then 0 else a.Ore_intrerupere_tehnologica+a.Ore end)
				-(case when @COEVMacheta=1 then a.Ore_obligatii_cetatenesti else 0 end)-isnull(cm.ZCM2ani,0)*a.Regim_de_lucru else a.Ore_regie end),
		Ore_acord=(case when a.Tip_salarizare not in ('1','3') and a.Ore_acord>0 
			then a.Ore_acord*(case when @RegimLV=1 and p.Salar_lunar_de_baza<>0 
					then (case when p.Grupa_de_munca='C' then a.Regim_de_lucru/8 else p.Salar_lunar_de_baza/(case when a.Tip_salarizare='1' then @OreLuna else @NrmLuna end) end) 
					else 1 end)
				-a.Ore_concediu_medical-(case when @COMacheta=1 then a.Ore_concediu_de_odihna else 0 end)-a.Ore_invoiri-a.Ore_nemotivate-a.Ore_concediu_fara_salar
				-(case when @InstPubl=1 then 0 else a.Ore_intrerupere_tehnologica+a.Ore end)
				-(case when @COEVMacheta=1 then a.Ore_obligatii_cetatenesti else 0 end) -isnull(cm.ZCM2ani,0)*a.Regim_de_lucru else a.Ore_acord end)
		from #pontaj_automat a
			left outer join personal p on a.Marca=p.Marca
			left outer join 
				(select marca, (case when @lPontajZilnic=1 then (case when max(Data_inceput)<=@DataIncr and @DataIncr<=max(Data_sfarsit) then 1 else 0 end) else sum(Zile_lucratoare) end) as ZCM2ani 
				from conmed where data between dbo.bom(@DataIncr) and dbo.eom(@DataIncr) and (@lPontajZilnic=1 and Data_inceput<=@DataIncr 
					and @DataIncr<=Data_sfarsit or @lPontajZilnic=0) and Tip_diagnostic='0-' Group by Marca) cm on a.Marca=cm.Marca

		update #pontaj_automat set 
			Ore__cond_1=(case when @Spc_ORN=1 and a.Spor_conditii_1<>0 then a.ore_regie+a.ore_acord else 0 end),
			Ore__cond_2=(case when @Spc_ORN=1 and a.Spor_conditii_2<>0 then a.ore_regie+a.ore_acord else 0 end),
			Ore__cond_3=(case when @Spc_ORN=1 and a.Spor_conditii_3<>0 then a.ore_regie+a.ore_acord else 0 end),
			Ore__cond_4=(case when @Spc_ORN=1 and a.Spor_conditii_4<>0 then a.ore_regie+a.ore_acord else 0 end),
			Ore__cond_5=(case when @Spc_ORN=1 and a.Spor_conditii_5<>0 then a.ore_regie+a.ore_acord else 0 end),
			Ore_donare_sange=(case when @Spc_ORN=1 and a.Spor_conditii_6<>0 then a.ore_regie+a.ore_acord else 0 end), 
			Ore__cond_6=round((a.Ore_regie+a.Ore_acord-(isnull(pb.Zile,0)*a.Regim_de_lucru+isnull(pz.Zile,0)*a.Regim_de_lucru)-
				(case when @lZileFaraTicheteAng=1 and DateAdd(day,@nZileFaraTichete,p.Data_angajarii_in_unitate)>=@dataJos 
					then dbo.psZileFaraTichete(@dataJos,@dataSus,a.marca)*a.Regim_de_lucru else 0 end)-a.Spor_cond_10)/
				(case when @lTicheteRL=1 and p.Grupa_de_munca='C' then 8 else a.Regim_de_lucru end)*
				(case when @lTicheteZLDim=1 and t.NrTichete<@OreLuna/8 then t.NrTichete/(@OreLuna/8) else 1 end),0)
		from #pontaj_automat a
			left outer join personal p on a.Marca=p.Marca
			left outer join dbo.fDate_pontaj_automat (@dataJos, @dataSus, @DataIncr, 'PB', '', 0, 0) pb on a.Marca=pb.Marca 
			left outer join dbo.fDate_pontaj_automat (@dataJos, @dataSus, @DataIncr, 'PZ', '', 0, 0) pz on a.Marca=pz.Marca
			left outer join (select marca, (case when dbo.iauExtinfopProc(Marca,'NRTICHETE')=0 then @nNrTichete else dbo.iauExtinfopProc(Marca,'NRTICHETE') end) as NrTichete 
							from personal) t on t.Marca=a.Marca

		update #pontaj_automat set Ore_lucrate=a.ore_regie+a.ore_acord,
			Ore__cond_6=(case when @lGestionareTichete=0 or @PontajW=1 and a.ore_regie+a.ore_acord<>0 or @lTicheteMarca=1 and p.Loc_de_munca_din_pontaj=0 
			then 0 
			else (case when @lTicheteZL=1 and (p.Grupa_de_munca in ('N','D','S') or p.Grupa_de_munca='C' and (p.Tip_colab='' or @lTicheteMarca=1) or p.Grupa_de_munca in ('P','O') and @lTicheteMarca=1) 
				then (case when Ore__cond_6>t.NrTichete then t.NrTichete else Ore__cond_6 end) 
				else (case when @lTicheteZL=0 and (p.Grupa_de_munca in ('N','D','S') or p.Grupa_de_munca='C' and p.Tip_colab='') 
					then (case when (month(p.Data_angajarii_in_unitate)=month(@DataIncr) and year(p.Data_angajarii_in_unitate)=year(@DataIncr) 
							or p.Loc_ramas_vacant=1 and month(p.Data_plec)=month(@DataIncr) and year(p.Data_plec)=year(@DataIncr)) 
						then (dbo.Zile_lucratoare((case when month(p.Data_angajarii_in_unitate)=month(@DataIncr) and year(p.Data_angajarii_in_unitate)=year(@DataIncr) 
							then p.Data_angajarii_in_unitate else dbo.bom(@DataIncr) end),
							(case when p.Loc_ramas_vacant=1 and month(p.Data_plec)=month(@DataIncr) and year(p.Data_plec)=year(@DataIncr) then DateAdd(day,-1,p.Data_plec) else dbo.eom(@DataIncr) end)) 
							- (case when @lTicheteZL=1 then 0 else @OreLuna/8-t.NrTichete end))
						else t.NrTichete*(case when @lTicheteRL=1 and p.Grupa_de_munca='C' then a.Regim_de_lucru/8 else 1 end) end)-
						(a.Ore_concediu_medical+a.Ore_concediu_de_odihna+a.Ore_nemotivate+a.Ore_concediu_fara_salar+a.Ore_obligatii_cetatenesti+ a.Spor_cond_10)/a.Regim_de_lucru else 0 end) end) end)
		from #pontaj_automat a 	
		-- legatura pe un select virtual pt. a avea nr. de tichete teoretic cuvenite pe marca (sa nu fie case when in fiecare loc unde se utiliza variabila @nNrTichete) 
			left outer join (select marca, (case when dbo.iauExtinfopProc(Marca,'NRTICHETE')=0 then @nNrTichete else dbo.iauExtinfopProc(Marca,'NRTICHETE') end) as NrTichete 
							from personal) t on t.Marca=a.Marca, personal p
		where a.Marca=p.Marca

		update #pontaj_automat set Ore__cond_6=0 from #pontaj_automat a where a.Ore__cond_6<0

		insert into pontaj (Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, 
			Tip_salarizare, Regim_de_lucru, Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, 
			Ore_de_noapte, Ore_intrerupere_tehnologica, Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, 
			Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program, Ore_sistematic_peste_program, Spor_specific, 
			Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, 
			Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)
		select Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru, Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, 
			Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, 
			Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, Salar_categoria_lucrarii, 
			Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program, Ore_sistematic_peste_program, Spor_specific, Spor_conditii_1, 
			Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, 
			Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10 
		from #pontaj_automat

		If @SalPeComenzi=1
			insert into realcom (Marca, Loc_de_munca, Numar_document, Data, Comanda, Cod_reper, Cod, Cantitate, Categoria_salarizare, Norma_de_timp, Tarif_unitar)
			select a.Marca, a.Loc_de_munca, 'PS'+rtrim(convert(char(10),a.Numar_curent)), a.Data, i.Centru_de_cost_exceptie, '', '', a.Ore_regie+a.Ore_acord, 1, 0, a.Salar_orar
			from #pontaj_automat a
				left outer join personal p on a.Marca=p.Marca
				left outer join infopers i on a.Marca=i.Marca
			where a.Marca=i.Marca and a.Marca=p.Marca
	End
	set @DataIncr = dateadd(day, 1, @DataIncr)
End
exec scriuIstPers @dataJ, @dataS, @pMarca, @pLocm, 1, 1
If @lGenerezPontaj=1
	if object_id('tempdb..#pontaj_automat') is not null drop table #pontaj_automat
if exists(select * from sysobjects where name='GenPontajSP3' and type='P') 
	exec GenPontajSP3 @dataJ, @dataS, @pMarca, @pLocm
if @lGestionareTichete=1 and @lGenerezPontaj=1 and @lTicheteMacheta=0
Begin
	select @dataJos=dbo.bom(@dataS), @dataSus=dbo.eom(@dataS)
	exec psCalculTichete @dataJos, @dataSus, @pMarca, @pLocm, 1, 1
End	
