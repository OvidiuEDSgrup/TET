--***
/*	functie pentru determinarea istoricului (baza de calcul) concediilor de de odihna */
Create function frapIstoricConcediiOdihna
	(@dataJos datetime, @dataSus datetime, @locm char(9)=null, @strict int=0, @marca char(6)=null, @functie char(6)=null, @grupamunca char(1)=null, @grupaexceptata int, 
	@tippersonal char(1)=null, @tipstat varchar(30)=null, @ordonare char(2), @alfabetic int, 
	@istoric_pt_zile_co_ramase int, @zile_ramase_fct_cuvenite_la_luna int=0, @listadreptCond char(1)='T')
returns @istoric_co table 
	(data datetime, marca char(6), nume char(50), lm char(9), den_lm char(30), zile_CO int, indemnizatie_co float, indemnizatie_co_an float, 
	baza_calcul_3 float, baza_calcul_2 float, baza_calcul_1 float, zile_calcul_3 float, zile_calcul_2 float, zile_calcul_1 float, zile_3luni float, 
	baza_calcul_luna float, zile_calcul_luna float, media_luna_curenta float, media_ultimelor_3_luni float, media_zilnica_co float, taxe_unitate float, total_chelt float, provizion float,
	Ordonare char(100))
as
begin 
	declare @ProcCasGr3 float, @ProcCasIndiv float, @ProcCCI float, @ProcCASSUnit float, @ProcSomajUnit float, @ProcFondGar float, @ProcFambp float, @ProcITM float, @ProcChelt float, 
	@Spv_co bit, @SPFS_co bit, @SPSpec_co bit, @SPSpp bit, @IndCond_co bit, @Sp1_co bit, @Sp2_co bit,@Sp3_co bit,  @Sp4_co bit,@Sp5_co bit, @Sp6_co bit, @Sp7_co bit, 
	@SPSpec_suma bit, @Sp1_suma bit, @Sp2_suma bit, @Sp3_suma bit,  @Sp4_suma bit, @Sp5_suma bit, @Sp6_suma bit, @SPFS_suma bit, @IndCond_suma bit,  @lProcfix_co bit, @nProcfix_co float,  
	@Suma_comp_co bit, @Suma_comp float,  @Spv_IndCond bit, @nOreLuna int, @nOreLuna_tura int, @NrMediu_Ore_Luna float, 
	@nbuton_calcul int, @zile_calcul_co float, @ore_calcul_co float, @bugetari bit, 
	@SPSpec_proc_suma bit, @baza_sPSpec float, @SPSpec_pers bit, @SPSpec_co_baza_suma bit, @SPSpec_co_nu_baza_suma bit, 
	@SpElcond bit, @SpDafora bit, @lRegimLV bit, @Remarul int
	
	set @ProcCasGr3 = dbo.iauParLN(@dataSus,'PS','CASGRUPA3')
	set @ProcCasIndiv = dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @ProcCCI = dbo.iauParLN(@dataSus,'PS','COTACCI')
	set @ProcCASSUnit = dbo.iauParLN(@dataSus,'PS','CASSUNIT')
	set @ProcSomajUnit = dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ')
	set @ProcFondGar = dbo.iauParLN(@dataSus,'PS','FONDGAR')
	set @ProcFambp = dbo.iauParLN(@dataSus,'PS','0.5%ACCM')
	set @ProcITM = dbo.iauParLN(@dataSus,'PS','1%-CAMERA')
	set @ProcChelt=@ProcCasGr3-@ProcCasIndiv+@ProcCCI+@ProcCASSUnit+@ProcSomajUnit+@ProcFondGar+@ProcFambp+@ProcITM
	set @Spv_co=dbo.iauParL('PS','CO-SP-V')
	set @SPFS_co=dbo.iauParL('PS','CO-F-SPL')
	set @SPSpec_co=dbo.iauParL('PS','CO-SPEC')
	set @SPSpp=dbo.iauParL('PS','CO-S-PR')
	set @IndCond_co=dbo.iauParL('PS','CO-IND')
	set @Sp1_co=dbo.iauParL('PS','CO-SP1')
	set @Sp2_co=dbo.iauParL('PS','CO-SP2')
	set @Sp3_co=dbo.iauParL('PS','CO-SP3')
	set @Sp4_co=dbo.iauParL('PS','CO-SP4')
	set @Sp5_co=dbo.iauParL('PS','CO-SP5')
	set @Sp6_co=dbo.iauParL('PS','CO-SP6')
	set @Sp7_co=dbo.iauParL('PS','CO-SP7')
	set @SPSpec_suma=dbo.iauParL('PS','SSP-SUMA')
	set @Sp1_suma=dbo.iauParL('PS','SC1-SUMA')
	set @Sp2_suma=dbo.iauParL('PS','SC2-SUMA')
	set @Sp3_suma=dbo.iauParL('PS','SC3-SUMA')
	set @Sp4_suma=dbo.iauParL('PS','SC4-SUMA')
	set @Sp5_suma=dbo.iauParL('PS','SC5-SUMA')
	set @Sp6_suma=dbo.iauParL('PS','SC6-SUMA')
	set @SPFS_suma=dbo.iauParL('PS','SPFS-SUMA')
	set @IndCond_suma=dbo.iauParL('PS','INDC-SUMA')
	set @lPRocfix_co=dbo.iauParL('PS','CO-SPFIX')
	set @nPRocfix_co=dbo.iauParN('PS','CO-SPFIX')
	set @Suma_comp=(case when dbo.iauParL('PS','CO-COMP')=1 then dbo.iauParN('PS','SUMACOMP') else 0 end)
	set @Spv_IndCond=dbo.iauParL('PS','SP-V-INDC')
	set @nOreLuna=(case when dbo.iauParLN(@dataSus,'PS','ORE_LUNA')=0 then dbo.iauParN('PS','ORE_LUNA') else dbo.iauParLN(@dataSus,'PS','ORE_LUNA') end)
	set @nOreLuna_tura=dbo.iauParLN(@dataSus,'PS','ORET_LUNA')
	if @nOreLuna_tura=0
		set @nOreLuna_tura=dbo.iauParN('PS','ORET_LUNA')
	set @NrMediu_Ore_Luna=(case when dbo.iauParLn(@dataSus,'PS','NRMEDOL')=0 then dbo.iauParN('PS','NRMEDOL') else dbo.iauParLn(@dataSus,'PS','NRMEDOL') end)
	set @nbuton_calcul=dbo.iauParN('PS','CALCUL-CO')
	set @zile_calcul_co=dbo.iauParN('PS','CO-NRZILE')
	set @ore_calcul_co=(case when @nbuton_calcul=1 then 8*@zile_calcul_co when @nbuton_calcul=2 then @nOreLuna else @NrMediu_Ore_Luna end)
	set @SPSpec_proc_suma=dbo.iauParL('PS','SSPEC')
	set @baza_sPSpec=dbo.iauParN('PS','SSPEC')
	set @SPSpec_pers=(case when @SPSpec_co=1 and @SPSpec_proc_suma=0 and @SPSpec_suma=0 then 1 else 0 end)
	set @SPSpec_co_baza_suma=(case when @SPSpec_co=1 and @SPSpec_proc_suma=1 then 1 else 0 end)
	set @SPSpec_co_nu_baza_suma=(case when @SPSpec_co=1 and @SPSpec_proc_suma=0 then 1 else 0 end)
	set @lRegimLV=dbo.iauParL('PS','REGIMLV')
	set @bugetari=dbo.iauParL('PS','UNITBUGET')
	set @SpElcond=dbo.iauParL('SP','ELCOND')
	set @SpDafora=dbo.iauParL('SP','DAFORA')
	set @Remarul=dbo.iauParL('SP','REMARUL')

	declare @dreptConducere int, @aredreptCond int, @lista_drept char(1), @data1_an datetime, @utilizator varchar(20)	-- pt filtrare pe PRoPRietatea loCmUnCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fiaUtilizator('')
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
--	verific daca utilizatorul are/nu are dreptul de Salarii Conducere (SALCOND)
	set @lista_drept=@listadreptCond
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @aredreptCond=0
			set @lista_drept='S'
	end
	set @data1_an=dbo.boy(@datasus)

	declare @zileco table (data datetime, marca char(6), zile_co int, indemnizatie_co float, indemnizatie_co_an float, zile_co_efectuat_an int)

--	stabilesc pentru ce zile se doreste calculul istoricului
/*
	@istoric_pt_zile_co_ramase=1 - determinare istoric pentru zilele de concediu de odihna ramase de efectuat
	@istoric_pt_zile_co_ramase=0 - determinare istoric pentru zilele de concediu de odihna efectuate in luna
*/
	if @istoric_pt_zile_co_ramase=0
	begin
		declare @tmpzileco table (data datetime, marca char(6), zile_co int)
		insert into @tmpzileco
		select dbo.eom(a.data), a.marca as marca, sum(a.ore_concediu_de_odihna/a.regim_de_lucru) as zile_co
		from pontaj a 
		where a.data between @datajos and @datasus and a.ore_concediu_de_odihna<>0
			and (@marca is null or a.marca=@marca) 
		group by dbo.eom(a.data), a.marca
		union all
		select co.data, co.Marca, sum(Zile_CO) as zile_co 
		from concodih co
		where co.data between @datajos and @datasus and co.Zile_CO<>0 and co.Tip_concediu in ('3','6')
			and (@marca is null or co.marca=@marca) 
		group by co.data, co.marca

		insert into @zileco
		select dbo.eom(a.data), a.marca as marca, sum(a.zile_co) as zile_co,
		isnull((select sum(r.ind_concediu_de_odihna) from brut r where r.data=@datasus and r.marca = a.marca),0) as indemnizatie_co, 
		isnull((select sum(r.ind_concediu_de_odihna) from brut r where r.data between @data1_an and @datasus and r.marca = a.marca),0) as indemnizatie_co_an, 0 as zile_co_efectuat_an
		from @tmpzileco a 
			left outer join personal p on a.marca=p.marca
			left outer join infopers ip on a.marca=ip.marca
			left outer join istpers i on a.data=i.data and a.marca=i.marca 
			left outer join lm on lm.COd = p.loc_de_munca 
		where @istoric_pt_zile_co_ramase=0 
			and (@locm is null or i.loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
			and (@functie is null or i.Cod_functie = @Functie)
			and (@grupamunca is null or (@grupaexceptata=0 and p.grupa_de_munca=@grupamunca or @grupaexceptata=1 and p.grupa_de_munca<>@grupamunca)) 
			and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7')))		
			and (@tiPStat is null or ip.religia=@tiPStat)
			and (@dreptCOnducere=0 or (@dreptCOnducere=1 and @aredreptCOnd=1 and (@lista_drept='t' or @lista_drept='C' and p.pensie_suplimentara=1 or @lista_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptCOnducere=1 and @aredreptCOnd=0 and @lista_drept='S' and p.pensie_suplimentara<>1))
			and (dbo.f_arelmFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare lu where lu.utilizator=@utilizator and lu.Cod=isnull(i.loc_de_munca,p.loc_de_munca)))			
		group by dbo.eom(a.data), a.marca
	end

	if @istoric_pt_zile_co_ramase=1
		insert into @zileco
		select a.data, a.marca, sum(a.zile_co_neefectuat_an_ant+(case when @zile_ramase_fct_cuvenite_la_luna=1 then zile_co_cuvenite_la_luna else a.zile_co_cuvenite_an end)-a.zile_co_efectuat_an), 0 as indemnizatie_co,  
		isnull((select sum(r.ind_concediu_de_odihna) from brut r where r.data between @data1_an and @datasus and r.marca = a.marca),0) as indemnizatie_co_an, sum(zile_co_efectuat_an) as zile_co_efectuat_an
		from dbo.frapConcediiOdihnaPeAn(@data1_an, @datasus, @marca, @locm, @strict, @functie, @grupamunca, @grupaexceptata, @tippersonal, @tipstat, 0, '', 0, @zile_ramase_fct_cuvenite_la_luna) a
		where a.zile_co_neefectuat_an_ant+(case when @zile_ramase_fct_cuvenite_la_luna=1 then zile_co_cuvenite_la_luna else a.zile_co_cuvenite_an end)-a.zile_co_efectuat_an<>0
		group by a.data, a.marca

--	determin baza de calcul (istoricul) pentru zilele de concediu de odihna stabilite anterior tinand cont de setarile privind baza de calcul a indemnizatiei
	declare @tmpistoricco table
		(data datetime, marca char(6), nume char(50), loc_de_munca char(9), denumire_lm char(30), zile_co int, indemnizatie_co float, 
		baza_calcul_3 float, baza_calcul_2 float, baza_calcul_1 float, zile_calcul_3 float, zile_calcul_2 float, zile_calcul_1 float,
		baza_calcul_luna float, zile_calcul_luna float, indemnizatie_co_an float, zile_co_efectuat_an int, 
		media_luna_curenta float, media_ultimelor_3_luni float, ordonare char(100))

	insert into @tmpistoricco
	select a.data, a.marca as marca, max(isnull(i.nume,p.nume)) as nume, max(isnull(i.loc_de_munca,p.loc_de_munca)) as lm, max(lm.denumire) as den_lm, 
	sum(a.zile_co) as zile_co, sum(a.indemnizatie_co) as indemnizatie_co,
	isnull(round((select sum(round(ind_regim_normal,0)+@Spv_co*b.spor_vechime+@SPFS_co*b.spor_de_functie_suplimentara+ @SPSpec_co*b.spor_specific+@SPSpp*b.spor_sistematic_peste_PRogram
		+@IndCond_co*b.ind_nemotivate+@Sp1_co*b.spor_cond_1+ @Sp2_co*b.spor_cond_2+@Sp3_co*b.spor_cond_3+@Sp4_co*b.spor_cond_4+@Sp5_co*b.spor_cond_5+@Sp6_co*b.spor_cond_6
		+ @Sp7_co*b.spor_cond_7+b.ind_obligatii_cetatenesti+(case when @SpElcond=0 then b.ind_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ind_intrerupere_tehnologica+b.Ind_invoiri else 0 end)) 
		from brut b where b.data = dbo.eom(dateadd(month,-3,a.data)) and b.marca = a.marca),0),0) as baza_luna_3,
	isnull(round((select sum(round(ind_regim_normal,0)+@Spv_co*b.spor_vechime+@SPFS_co*b.spor_de_functie_suplimentara+ @SPSpec_co*b.spor_specific+@SPSpp*b.spor_sistematic_peste_PRogram
		+@IndCond_co*b.ind_nemotivate+@Sp1_co*b.spor_cond_1+ @Sp2_co*b.spor_cond_2+@Sp3_co*b.spor_cond_3+@Sp4_co*b.spor_cond_4+@Sp5_co*b.spor_cond_5+@Sp6_co*b.spor_cond_6
		+ @Sp7_co*b.spor_cond_7+b.ind_obligatii_cetatenesti+(case when @SpElcond=0 then b.ind_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ind_intrerupere_tehnologica+b.Ind_invoiri else 0 end)) 
		from brut b where b.data = dbo.eom(dateadd(month,-2,a.data)) and b.marca = a.marca),0),0) as baza_luna_2,
	isnull(round((select sum(round(ind_regim_normal,0)+@Spv_co*b.spor_vechime+@SPFS_co*b.spor_de_functie_suplimentara+ @SPSpec_co*b.spor_specific+@SPSpp*b.spor_sistematic_peste_PRogram
		+@IndCond_co*b.ind_nemotivate+@Sp1_co*b.spor_cond_1+ @Sp2_co*b.spor_cond_2+@Sp3_co*b.spor_cond_3+@Sp4_co*b.spor_cond_4+@Sp5_co*b.spor_cond_5+@Sp6_co*b.spor_cond_6
		+ @Sp7_co*b.spor_cond_7+b.ind_obligatii_cetatenesti+(case when @SpElcond=0 then b.ind_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ind_intrerupere_tehnologica+b.Ind_invoiri else 0 end)) 
		from brut b where b.data = dbo.eom(dateadd(month,-1,a.data)) and b.marca = a.marca),0),0) as baza_luna_1,
	isnull((select round(sum((case when (b.ore_lucrate_regim_normal+b.ore_obligatii_cetatenesti+(case when @SpElcond=0 then b.ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ore_intrerupere_tehnologica else 0 end))=0 then 1 
		else (b.ore_lucrate_regim_normal+b.ore_obligatii_cetatenesti+(case when @SpElcond=0 then b.ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ore_intrerupere_tehnologica else 0 end)) end)/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)),0) 
		from brut b where b.data = dbo.eom(dateadd(month,-3,a.data)) and b.marca = a.marca),0) as zile_luna_3,
	isnull((select round(sum((case when (b.ore_lucrate_regim_normal+b.ore_obligatii_cetatenesti+(case when @SpElcond=0 then b.ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ore_intrerupere_tehnologica else 0 end))=0 then 1 
		else (b.ore_lucrate_regim_normal+b.ore_obligatii_cetatenesti+(case when @SpElcond=0 then b.ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ore_intrerupere_tehnologica else 0 end)) end)/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)),0) 
		from brut b where b.data = dbo.eom(dateadd(month,-2,a.data)) and b.marca = a.marca),0) as zile_luna_2,
	isnull((select round(sum((case when (b.ore_lucrate_regim_normal+b.ore_obligatii_cetatenesti+(case when @SpElcond=0 then b.ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ore_intrerupere_tehnologica else 0 end))=0 then 1 
		else (b.ore_lucrate_regim_normal+b.ore_obligatii_cetatenesti+(case when @SpElcond=0 then b.ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then b.Ore_intrerupere_tehnologica else 0 end)) end)/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)),0) 
		from brut b where b.data = dbo.eom(dateadd(month,-1,a.data)) and b.marca = a.marca),0) as zile_luna_1,
	round(max(((case when @bugetari=1 then i.salar_de_baza else i.salar_de_incadrare end)*
	(100 +@Spv_co*i.spor_vechime+@SPFS_co*(case when @SPFS_suma=1 then 0 else i.spor_de_functie_suplimentara end)+ @SPSpec_pers*i.spor_specific+@SPSpp*i.spor_sistematic_peste_PRogram+ 
		@Sp1_co*(case when @Sp1_suma=1 then 0 else i.spor_conditii_1 end)+@Sp2_co*(case when @Sp2_suma=1 then 0 else p.spor_conditii_2 end)+ @Sp3_co*(case when @Sp3_suma=1 then 0 else i.spor_conditii_3 end)+ 
		@Sp4_co*(case when @Sp4_suma=1 then 0 else i.spor_conditii_4 end)+
		@Sp5_co*(case when @Sp5_suma=1 then 0 else i.spor_conditii_5 end)+@Sp6_co*(case when @Sp6_suma=1 then 0 else i.spor_conditii_6 end)+@Sp7_co*ip.spor_cond_7+ 
		(case when @IndCond_suma=0 then @IndCond_co*i.indemnizatia_de_conducere else 0 end)+@lPRocfix_co*@nPRocfix_co)/100+ @SPSpec_co_baza_suma*@baza_sPSpec*i.spor_specific/100+ 
		@SPSpec_co_nu_baza_suma*(case when @SPSpec_suma=1 then i.spor_specific else 0 end) +@Spv_co*i.spor_vechime/100*@Spv_IndCond*i.indemnizatia_de_conducere*(case when @IndCond_suma=0 then i.salar_de_incadrare/100 else 1 end)+
		(case when @IndCond_suma=1 then @IndCond_co*i.indemnizatia_de_conducere else 0 end)+@Suma_comp+@SPFS_co*(case when @SPFS_suma=1 then i.spor_de_functie_suplimentara else 0 end)+
		@Sp1_co*(case when @Sp1_suma=1 then i.spor_conditii_1 else 0 end)+@Sp2_co*(case when @Sp2_suma=1 then i.spor_conditii_2 else 0 end)+@Sp3_co*(case when @Sp3_suma=1 then i.spor_conditii_3 else 0 end)+
		@Sp4_co*(case when @Sp4_suma=1 then i.spor_conditii_4 else 0 end)+@Sp5_co*(case when @Sp5_suma=1 then i.spor_conditii_5 else 0 end)+@Sp6_co*(case when @Sp6_suma=1 then i.spor_conditii_6 else 0 end))),0) as baza_calcul_luna,
		(case when @lRegimLV=1 and @nOreLuna_tura<>0 and max(i.salar_lunar_de_baza)<>0 then @nOreLuna_tura when @nbuton_calcul=4 and max(i.tip_salarizare) in ('1','2') then @nOreLuna/8 
		when @nbuton_calcul=4 and max(i.tip_salarizare) not in ('1','2') then @NrMediu_Ore_Luna/8 else @ore_calcul_co/8 end) as zile_calcul_luna, 
		sum(a.indemnizatie_co_an) as indemnizatie_co_an, sum(a.zile_co_efectuat_an) as zile_co_efectuat_an, 0, 0, 
		(case when @ordonare='2' then max(isnull(i.loc_de_munca,p.loc_de_munca)) else '' end) as ordonare
	from @zileco a 
		left outer join personal p on a.marca=p.marca
		left outer join infopers ip on a.marca=ip.marca
		left outer join istpers i on a.data=i.data and a.marca=i.marca 
		left outer join lm on lm.COd = isnull(i.Loc_de_munca,p.loc_de_munca)
	where a.data between @datajos and @datasus and a.zile_co<>0
	group by a.data, a.marca
	order by ordonare,(case when @Alfabetic=1 then max(p.nume) else a.marca end)

--	recalculare indemnizatie CO si calcul media zilnica a concediului de odihna
	update @tmpistoricco
		set indemnizatie_co=(case when @istoric_pt_zile_co_ramase=1 then (case when zile_co<0 and zile_co_efectuat_an<>0 then round(zile_co*indemnizatie_co_an/zile_co_efectuat_an,0) else 
	round((case when zile_calcul_3+zile_calcul_2+zile_calcul_1<>0 and  round((baza_calcul_3+baza_calcul_2+baza_calcul_1)/(zile_calcul_3+zile_calcul_2+zile_calcul_1),3)>round(baza_calcul_luna/zile_calcul_luna,3) 
	then round((baza_calcul_3+baza_calcul_2+baza_calcul_1)/(zile_calcul_3+zile_calcul_2+zile_calcul_1),3) else round(baza_calcul_luna/zile_calcul_luna,3) end)*zile_co,0) end) else indemnizatie_co end),
	media_luna_curenta=round(baza_calcul_luna/zile_calcul_luna,3),
	media_ultimelor_3_luni=(case when zile_calcul_3+zile_calcul_2+zile_calcul_1<>0 then round((baza_calcul_3+baza_calcul_2+baza_calcul_1)/(zile_calcul_3+zile_calcul_2+zile_calcul_1),3) else 0 end)

-- returnare date de afisat
	insert into @istoric_co
	select data, marca, nume, loc_de_munca, denumire_lm, zile_co, indemnizatie_co, indemnizatie_co_an, 
	baza_calcul_3, baza_calcul_2, baza_calcul_1, zile_calcul_3, zile_calcul_2, zile_calcul_1, zile_calcul_3+zile_calcul_2+zile_calcul_1 as zile_3luni, baza_calcul_luna, zile_calcul_luna, 
	media_luna_curenta, media_ultimelor_3_luni, (case when media_luna_curenta>media_ultimelor_3_luni then media_luna_curenta else media_ultimelor_3_luni end) as medie_zilnica_co, 
	round(indemnizatie_co*@ProcChelt/100,0) as taxe_unitate, indemnizatie_co+round(indemnizatie_co*@ProcChelt/100,0) as total_chelt, 
	isnull((select sum(c.Indemnizatie_co+c.Prima_vacanta) from concOdih c where c.data between @data1_an and @dataSus and c.marca=marca and c.tip_concediu='C'),0)-Indemnizatie_co_an as provizion, 
	ordonare
	from @tmpistoricco
	order by ordonare,(case when @Alfabetic=1 then nume else marca end)

	return
end
