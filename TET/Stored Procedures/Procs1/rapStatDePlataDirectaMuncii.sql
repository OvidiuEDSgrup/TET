--***
/*	procedura pt. raportul Stat de plata directia muncii.RDL
*/
Create procedure rapStatDePlataDirectaMuncii
	(@datajos datetime, @datasus datetime, @locm varchar(20), @grupamunca varchar(10), @tipstat varchar(30), @marca varchar(20), @functie varchar(6), @ven_tot_poz int, 
	@tipraport char(1), @alfabetic varchar(1), @ordonare int, @nivelLm int=100, 
	@tipSalarizare char(1)=null, --> null-Toti salariatii, T-Tesa, M-Muncitori
	@tipangajat char(1)=null, --> null-Toti angajatii, C-Colaboratori, S-Salariati
	@setlm varchar(20)=null	-->	set de locuri de munca (proprietate TIPBALANTA)
	)
/*
	@tipraport = 1 ->	raport Standard
	@tipraport = 2 ->	raport Special ; doar in PSplus - pentru moment procedura nu este integrata in PSplus.
	@tipraport = 3 ->	raport Condensat
*/
as
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#brut1') is not null drop table #brut1
	if object_id('tempdb..#de_regrupat') is not null drop table #de_regrupat

	declare @utilizator varchar(20), @impozitareTichete int, @datajosTich datetime, @datasusTich datetime,
		@dreptConducere int, @NuCAS_H int, @Cassimps_K int, @AjDecesUnit int, @Dafora int, @Pasmatex int,
		@Helvetica int, @Colas int, @Stoehr int, @listaDreptCond char(1), @areDreptCond int, @lungLm int

	set @lungLm=isnull((select lungime from strlm where nivel=@nivelLm),
					(case when @nivelLm is not null and @nivelLm<0 then 0 else 1000 end))
	set @utilizator=dbo.fIaUtilizator(null)
	set @impozitareTichete=dbo.iauParLL(@datasus,'PS','DJIMPZTIC')
	set @datajosTich=dbo.iauParLD(@datasus,'PS','DJIMPZTIC')
	set @datasusTich=dbo.iauParLD(@datasus,'PS','DSIMPZTIC')
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
	set @Cassimps_K=dbo.iauParL('PS','ASSIMPS-K')
	set @AjDecesUnit=dbo.iauParL('PS','AJDUNIT-R')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @Helvetica=dbo.iauParL('SP','HELVETICA')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @Stoehr=dbo.iauParL('SP','STOEHR')

	if object_id('tempdb..#brut1') is not null drop table #brut1
	
	set @listaDreptCond='T'
	set @areDreptCond=0
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0 -- daca utilizatorul nu are drept conducere atunci are acces doar la cei de tip salariat
			set @listaDreptCond='S'
	end
	
--	creare tabela temporara in care se cumuleaza sumele din tabela brut pe marca
	select max(b.marca) as marca, max(b.data) as data, 
	sum((case when @Helvetica=1 then (b.ore_lucrate__regie+b.ore_suplimentare_1+b.ore_suplimentare_2) else b.total_ore_lucrate end)
	-(case when @Dafora=1 and pd.marca is not null then pd.ore_regie else 0 end)) as tore_lucrate_m, 
	sum(b.ore_lucrate_regim_normal) as tore_regim_normal_lucru, sum(b.ore_concediu_de_odihna) as tore_co_m, 
	sum(b.ore_concediu_medical) as tore_cm_m, sum(b.ore_invoiri) as tore_invoiri_m, sum(b.ore_nemotivate) as tore_nemotivate_m,
	sum(round (b.ore_concediu_de_odihna/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as total_zile_CO_m, 
	sum(round (b.ore_concediu_medical/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as total_zile_CM_m,
	(case when max(isnull(ca.Zile_CFS,0))<>0 and max(b.spor_cond_10)<1 then max(isnull(ca.Zile_CFS,0)) 
		else sum(round (b.ore_concediu_fara_salar/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) end) as total_zile_CFS_m,
	sum(b.ore_concediu_fara_salar) as tore_CFS_m,
	max(isnull(ca.Zile_CD,0)) as total_zile_CD_m, 
	sum(round (b.ore_nemotivate/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as total_zile_nemotivate_m, 
	sum(round (b.ore_invoiri/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as total_zile_invoiri_m,
	sum(round (b.ore_concediu_fara_salar/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0))
		+sum(round (b.ore_nemotivate/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0))
		+sum(round (b.ore_invoiri/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as total_zile_fara_plata_m,
	sum(round (b.ore_obligatii_cetatenesti/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as total_zile_oblig_cetatenesti_m, 
	sum(round (b.ore_obligatii_cetatenesti,2,0)) as total_ore_oblig_cetatenesti_m,
	sum(round ((b.ore_obligatii_cetatenesti+b.ore_intrerupere_tehnologica+(case when @Colas=1 then po.Ore_intemperii else 0 end))/
		(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),0)) as total_zile_oblig_intrerupere_m, 
	sum(round ((b.ore_obligatii_cetatenesti+b.ore_intrerupere_tehnologica),0)) as tore_oblig_intrerupere_m, 
	sum(b.ore_suplimentare_1+(case when @Pasmatex=1 then (b.ore_suplimentare_2+b.ore_suplimentare_3+b.ore_suplimentare_4) else 0 end)) as total_ore_suplimentare_m, 
	sum(b.ore_suplimentare_1) as total_ore_suplimentare_1_m,
	sum((case when @Pasmatex=1 then 0 else b.ore_suplimentare_2 end)-(case when @Dafora=1 and pd.marca is not null then b.ore_suplimentare_2 else 0 end))
		as total_ore_suplimentare_2_m,
	sum((case when @Pasmatex=1 then 0 else b.ore_suplimentare_3 end)-(case when @Dafora=1 and pd.marca is not null then b.ore_suplimentare_3 else 0 end)) 
		as total_ore_suplimentare_3_m,
	sum((case when @Pasmatex=1 then 0 else b.ore_suplimentare_4 end)-(case when @Dafora=1 and pd.marca is not null then b.ore_suplimentare_4 else 0 end)) 
		as total_ore_suplimentare_4_m,
	sum(b.ore_spor_100) as total_ore_spor_100_m, 
	sum(b.ore_suplimentare_1+b.ore_suplimentare_2+b.ore_suplimentare_3+b.ore_suplimentare_4+b.ore_spor_100) as total_ore_suplim_standard_m, 
	sum(b.indemnizatie_ore_supl_1+b.indemnizatie_ore_supl_2+b.indemnizatie_ore_supl_3+b.indemnizatie_ore_supl_4+b.indemnizatie_ore_spor_100) as total_ind_ore_supl_standard_m,
	sum(b.indemnizatie_ore_spor_100+b.spor_sistematic_peste_program+b.suma_impozabila) as tind_ore_supli_m_fara1_4, 
	sum(b.indemnizatie_ore_supl_1) as tind_ore_supl_1_m, sum(b.indemnizatie_ore_supl_2) as tind_ore_supl_2_m, 
	sum(b.indemnizatie_ore_supl_3) as tind_ore_supl_3_m, sum(b.indemnizatie_ore_supl_4) as tind_ore_supl_4_m,
	sum(b.indemnizatie_ore_spor_100) as tind_ore_spor_100_m,
	sum(b.ore_de_noapte) as tore_noapte_m, sum(round(b.ind_ore_de_noapte,0)) as tind_ore_noapte_m, 
	sum(round(b.spor_sistematic_peste_program,0)+round(b.spor_de_functie_suplimentara,0)+round(b.ind_nemotivate,0)+round(b.spor_specific,0)
		+round(b.spor_cond_1,0)+round(b.spor_cond_2,0)+round(b.spor_cond_3,0)+round(b.spor_cond_4,0)+round(b.spor_cond_5,0)+round(b.spor_cond_6,0)
		+round(b.Spor_cond_7,0)) as total_sporuri_m, 
		sum(b.premiu+b.suma_impozabila+b.Cons_admin) as premii, sum(b.diminuari) as tdiminuari_m, 
	sum(round(b.realizat__regie,0)+round(b.realizat_acord,0)+round(b.sp_salar_realizat,0)) as tsalar_t_ef_m, sum(b.spor_vechime) as tsp_vechime_m, 
	sum(b.indemnizatie_ore_supl_1+b.indemnizatie_ore_supl_2+b.indemnizatie_ore_supl_3+b.indemnizatie_ore_supl_4
	+(case when @tipraport='2' then 0 else b.indemnizatie_ore_spor_100 end)+b.ind_ore_de_noapte+b.premiu+b.suma_impozabila+
	(case when @tipraport='4' then b.ind_intrerupere_tehnologica+b.ind_invoiri+b.spor_cond_8 end)) as tind_ore_supl_m, 
	sum(b.premiu+b.suma_impozabila+b.spor_sistematic_peste_program) as tpt_calcul_alte_drepturi_m,
	sum(round(b.spor_sistematic_peste_program,0)+round(b.spor_de_functie_suplimentara,0)+round(b.ind_nemotivate,0)+round(b.spor_specific,0)
		+round(b.spor_cond_1,0)+round(b.spor_cond_2,0)+round((case when @Dafora=0 then b.spor_cond_3 else 0 end),0)+round(b.spor_cond_4,0)+round(b.spor_cond_5,0)
		+round(b.spor_cond_6,0)+round(b.Spor_cond_7,0)
		-round((case when @Stoehr=1 or @tipraport='2' then 0 else b.diminuari end),0)+round((case when @tipraport='2' then 0 else b.restituiri end),0)) as tsporuri_m,
	sum(b.diminuari+b.restituiri+b.Premiu+b.Diurna+b.Cons_admin+b.suma_impozabila) as tcorectii_m, 
	sum(b.spor_cond_3) as tspor_conditii_3, sum(b.restituiri) as restituiri,
	sum(round(b.ind_concediu_de_odihna,0)+b.co+(case when @tipraport='2' then 0 else round(b.ind_obligatii_cetatenesti,0)+b.suma_imp_separat end)
		+(case when @tipraport='2' then b.Cons_admin else 0 end)) as tind_co_m, 
	sum(b.ind_c_medical_unitate)+sum(b.CMunitate) as tind_cm_unit_m, 
	sum(b.ind_c_medical_CAS)+sum(b.CMCAS) as tind_cm_cas_m, 
	sum(b.spor_cond_9) as tind_cm_fambp_m,
	isnull((select sum(zile_cu_reducere) from conmed where data=b.data and marca=b.marca),0) as total_zile_cm_unit_m, 
	isnull((select sum(zile_lucratoare-zile_cu_reducere) from conmed where data=b.data and marca=b.marca 
		and (not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or (tip_diagnostic='10' or tip_diagnostic='11') and suma=1))),0) as total_zile_cm_cas_m, 
	isnull((select sum(zile_lucratoare-zile_cu_reducere) from conmed where data=b.data and marca=b.marca 
		and ((tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or (tip_diagnostic='10' or tip_diagnostic='11') and suma=1))),0) as total_zile_cm_fambp_m,
	sum(b.spor_cond_1+b.spor_cond_2+b.spor_cond_3+b.spor_cond_4+b.spor_cond_5+b.spor_cond_6) as tspor_conditie_1_6_m,
	sum(b.venit_total) as tdrepturi_m, sum(b.venit_total-b.ind_concediu_de_odihna-ind_c_medical_unitate-b.premiu
		-b.indemnizatie_ore_supl_1-b.indemnizatie_ore_supl_2-b.indemnizatie_ore_supl_3-b.indemnizatie_ore_supl_4) as tbrut_m, 
	max(n.VENIT_BAZA) as venit_impozabil_m, 
	sum(b.premiu) as tpremiu_m, 
	sum((case when @tipraport='2' then 0 else b.Cons_admin+b.Sp_salar_realizat end)) as AlteCorectii,
	sum((case when @tipraport='2' then 0 else b.Cons_admin+b.Suma_imp_separat+b.Sp_salar_realizat end)) as AlteCorectii1,
	sum(round (b.ore_intrerupere_tehnologica+(case when @Colas=1 then po.Ore_intemperii else 0 end)/
		(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end),2,0)) as zile_intrerupere_teh_m,
	sum(round (b.ore_intrerupere_tehnologica,2,0)) as tore_intrerupere_teh_m, 
	sum(ind_intrerupere_tehnologica+ind_invoiri) as ind_intrerupere_tehnologica_m, sum(b.ind_regim_normal) as ind_o_regim_normal,
	sum(b.diminuari) as retineri_si_avans, sum(case when @Stoehr=1 then b.diminuari else 0 end) as co_necuvenit_stoehr,
	sum((case when n.Camera_de_Munca_1<>0 
		then (b.venit_total-(b.ind_c_medical_cas+b.cmcas+b.spor_cond_9)-(case when @NuCAS_H=1 then b.suma_impozabila else 0 end)
			-(case when @Cassimps_K=1 then b.cons_admin else 0 end)) 
		else 0 end)) as baza_comision, 
	max((case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)) as spor_cond_10, 
	sum(po.Zile_lucrate) as Zile_lucrate, sum(b.Diurna) as Diurna, sum(round(b.sp_salar_realizat,0)) as Sp_salar_realizat, max(isnull(t.Valoare_tichete,0)) as Valoare_tichete, 
	sum((case when @AjDecesUnit=0 then b.compensatie else 0 end)) as Aj_deces, 
	sum(b.CO) as CO, sum(b.Suma_imp_separat) as Suma_imp_separat, sum(b.spor_cond_4) as spor_cond_4, sum(b.spor_cond_5) as spor_cond_5, sum(ore_spc_4) as ore_spc_4, sum(ore_spc_5) as ore_spc_5, 
	max(b.loc_de_munca) as loc_de_munca
	into #brut1 from brut b 
		left outer join istpers i on b.data=i.data and b.marca=i.marca
		left outer join pontaj pd on b.loc_de_munca=pd.loc_de_munca and b.marca=pd.marca and b.data=pd.data and pd.tip_salarizare='6'
		left outer join net n on b.marca=n.marca and b.data=n.data
		left outer join personal p on b.marca=p.marca
		left outer join (select marca, loc_de_munca, sum(spor_cond_8) as Ore_intemperii, sum(Coeficient_de_timp) as Zile_lucrate, sum(Ore__cond_4) as ore_spc_4, sum(Ore__cond_5) as ore_spc_5
			from pontaj where data between @datajos and @datasus group by marca, loc_de_munca) po on b.marca=po.marca and b.loc_de_munca=po.loc_de_munca
		left outer join (select data, marca, sum((case when tip_concediu='1' then Zile else 0 end)) as Zile_CFS, 
			sum((case when tip_concediu='9' then Zile else 0 end)) as Zile_CD 
				from conalte where data between @datajos and @datasus and Tip_concediu in ('1','9') group by data, marca) ca on b.data=ca.data and b.marca=ca.marca
		left outer join dbo.fNC_tichete (@datajosTich, @datasusTich, '', 1) t on @impozitareTichete=1 and b.Marca=t.Marca /*b.Data=t.Data and */
		left join par p10 on p10.parametru='NCALPCMC'
		left join par p11 on p11.parametru='NCALPCMPE'
	where b.data between @datajos and @datasus
	group by b.data, b.marca 
	order by b.data,b.marca

	if exists (select * from sysobjects where name ='rapStatDePlataDirectiaMunciiSP' and xtype='P')
		exec rapStatDePlataDirectiaMunciiSP @datajos, @datasus, @locm, @grupamunca, @tipstat, @marca, @functie, @ven_tot_poz, 
			@tipraport, @alfabetic, @ordonare, @nivelLm, @tipSalarizare, @tipangajat, @setlm

	select n.data, n.marca, left((case when 1=0 then n.loc_de_munca else i.loc_de_munca end),@lungLm) as lm, rtrim(lm.denumire) den_lm, 
		p.data_angajarii_in_unitate, p.data_plec, p.loc_ramas_vacant, m.mandatar, 
		rtrim(i.nume) nume, i.cod_functie, rtrim(f.denumire) as den_functie, i.tip_salarizare, i.mod_angajare, i.salar_de_incadrare, 
		i.salar_de_baza, i.spor_vechime, i.tip_impozitare, i.grupa_de_munca, i.spor_sistematic_peste_program, 
		i.spor_de_functie_suplimentara, i.spor_specific, i.spor_conditii_1, i.spor_conditii_2, i.spor_conditii_3, i.spor_conditii_4,
		i.spor_conditii_5, i.spor_conditii_6, n.loc_de_munca, n.CM_incasat, n.CO_incasat, n.suma_incasata, 
		n.suma_neimpozabila, n.diferenta_impozit, n.asig_sanatate_din_impozit, n.asig_sanatate_din_net, n.pensie_suplimentara_3, 
		n.somaj_1, n.chelt_prof, n.VEN_NET_IN_IMP, n.ded_baza+isnull(n1.ded_baza,0) as ded_baza, n.ded_suplim+isnull(n1.ded_suplim,0) as cci, 
		n.VENIT_BAZA, n.impozit, n.VENIT_NET, n.avans, n.debite_externe, n.rate, n.debite_interne, n.cont_curent, n.REST_DE_PLATA, b.Valoare_tichete, 
		n.Baza_CAS, n.fond_de_risc_1, n.asig_sanatate_din_CAS, n.asig_sanatate_pl_unitate, 
		n.Camera_de_Munca_1, n.somaj_5, n1.somaj_5 as fond_garantare, b.loc_de_munca, b.spor_cond_10, 
		b.tore_lucrate_m, b.tore_regim_normal_lucru, b.tore_co_m, b.tore_CFS_m, b.tore_cm_m, b.tore_invoiri_m, b.tore_nemotivate_m, b.total_zile_CO_m,
		b.total_zile_CFS_m, b.total_zile_nemotivate_m, b.total_zile_invoiri_m, b.total_zile_fara_plata_m, 
		b.total_zile_oblig_cetatenesti_m, b.total_ore_oblig_cetatenesti_m, b.tore_oblig_intrerupere_m, b.total_ore_suplimentare_m, 
		b.total_ore_suplim_standard_m, b.total_ind_ore_supl_standard_m, b.tind_ore_supli_m_fara1_4, b.tind_ore_supl_1_m, b.tind_ore_supl_2_m, b.tind_ore_supl_3_m, b.tind_ore_supl_4_m, 
		b.tore_noapte_m, b.tind_ore_noapte_m,b.total_sporuri_m, b.premii, b.tdiminuari_m, b.tsalar_t_ef_m, b.tsp_vechime_m, b.tind_ore_supl_m, b.tpt_calcul_alte_drepturi_m, 
		b.tsporuri_m, b.tspor_conditii_3, b.restituiri, tind_co_m, b.tind_cm_unit_m, b.tind_cm_cas_m, b.tind_cm_fambp_m, b.tspor_conditie_1_6_m, b.tdrepturi_m, b.tbrut_m,
		b.venit_impozabil_m, b.tpremiu_m, b.zile_intrerupere_teh_m, b.ind_intrerupere_tehnologica_m, b.ind_o_regim_normal,
		b.tdiminuari_m, b.co_necuvenit_stoehr, b.baza_comision, b.total_zile_cm_unit_m, b.total_zile_cm_cas_m, b.total_zile_cm_fambp_m, b.tcorectii_m as corectii, 
		p.cod_numeric_personal, p.somaj_1, (case when isnull(rtrim(x.val_inf),'')<>'' then isnull(rtrim(x.val_inf),'') else ip.Nr_contract end) as nr_contract, 
		isnull(fc.cod_functie,'') as cod_cor, isnull(fc.denumire,'') den_cor, 
		(case when @ordonare='5' then i.Tip_impozitare else '' end) as tip_impozitare_ord
	--into #de_regrupat
	from net n 
		left outer join personal p on n.marca=p.marca 
		left outer join istpers i on n.data=i.data and n.marca=i.marca 
		left outer join infopers ip on n.marca=ip.marca
		left outer join lm on left(i.loc_de_munca,@lungLm)=lm.cod
		left outer join mandatar m on i.loc_de_munca=m.loc_munca
		left outer join functii f on i.cod_functie=f.cod_functie
		left outer join #brut1 b on n.data=b.data and n.marca=b.marca 
		left outer join net n1 on n1.data=dbo.BOM(n.Data) and n1.marca=n.marca
		left outer join extinfop x on x.marca = n.marca and x.cod_inf='CNTRITM'
		left outer join extinfop cc on i.cod_functie=cc.marca and cc.cod_inf='#CODCOR' 
		left outer join functii_cor fc on cc.val_inf=fc.Cod_functie
	where n.data = @datasus
		and (@marca is null or n.marca=@marca)
		and (@locm is null or n.loc_de_munca like rtrim(@locm)+'%') 
		and (@functie is null or i.cod_functie=@functie)
		and (@grupamunca is null or i.grupa_de_munca=@grupamunca)
		and (@ven_tot_poz=0 or n.venit_total>0) 
		and (@dreptConducere=0 or (@AreDreptCond=1 and (@ListaDreptCond='T' or @ListaDreptCond='C' and p.pensie_suplimentara=1 or @ListaDreptCond='S' and p.pensie_suplimentara<>1)) 
			or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@tipSalarizare is null or @tipSalarizare='T' and i.Tip_salarizare in ('1','2') or @tipSalarizare='M' and i.Tip_salarizare in ('3','4','5','6','7'))
		and (@tipangajat is null or @tipangajat='C' and i.Grupa_de_munca in ('P','O') or @tipangajat='S' and i.Grupa_de_munca in ('N','D','S','C'))
		and (@setlm is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and p.Valoare=@setlm and rtrim(i.Loc_de_munca) like rtrim(p.cod)+'%'))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=n.Loc_de_munca))
	order by tip_impozitare_ord desc, (case @ordonare when '1' then (case when @alfabetic='0' then n.marca else p.nume end) when '3' then i.cod_functie	else i.loc_de_munca end), 
		(case when @ordonare='4' then i.cod_functie else '' end),
		(case when @alfabetic='0' then n.marca else p.nume end)
/*
	select data, marca, lm, den_lm, data_angajarii_in_unitate, data_plec, loc_ramas_vacant,
		mandatar, nume, cod_functie, den_functie, tip_salarizare, mod_angajare, salar_de_incadrare,
		salar_de_baza, spor_vechime, tip_impozitare, grupa_de_munca, spor_sistematic_peste_program,
		spor_de_functie_suplimentara, spor_specific, spor_conditii_1, spor_conditii_2,
		spor_conditii_3, spor_conditii_4, spor_conditii_5, spor_conditii_6, loc_de_munca,
		CM_incasat,	CO_incasat, suma_incasata, suma_neimpozabila, diferenta_impozit,
		asig_sanatate_din_impozit, asig_sanatate_din_net, pensie_suplimentara_3, somaj_1,
		chelt_prof, VEN_NET_IN_IMP, ded_baza, cci, VENIT_BAZA, impozit, VENIT_NET, avans,
		debite_externe, rate, debite_interne, cont_curent, REST_DE_PLATA, Valoare_tichete,
		Baza_CAS, fond_de_risc_1, asig_sanatate_din_CAS, asig_sanatate_pl_unitate,
		Camera_de_Munca_1, somaj_5, fond_garantare, loc_de_munca, spor_cond_10, tore_lucrate_m,
		tore_regim_normal_lucru, tore_co_m, tore_CFS_m, tore_cm_m, tore_invoiri_m,
		tore_nemotivate_m, total_zile_CO_m, total_zile_CFS_m, total_zile_nemotivate_m,
		total_zile_invoiri_m, total_zile_fara_plata_m, total_zile_oblig_cetatenesti_m,
		total_ore_oblig_cetatenesti_m, tore_oblig_intrerupere_m, total_ore_suplimentare_m,
		total_ore_suplim_standard_m, total_ind_ore_supl_standard_m, tind_ore_supli_m_fara1_4,
		tind_ore_supl_1_m, tind_ore_supl_2_m, tind_ore_supl_3_m, tind_ore_supl_4_m, tore_noapte_m,
		tind_ore_noapte_m, total_sporuri_m, premii, tdiminuari_m, tsalar_t_ef_m, tsp_vechime_m,
		tind_ore_supl_m, tpt_calcul_alte_drepturi_m, tsporuri_m, tspor_conditii_3, restituiri,
		tind_co_m, tind_cm_unit_m, tind_cm_cas_m, tind_cm_fambp_m, tspor_conditie_1_6_m,
		tdrepturi_m, tbrut_m, venit_impozabil_m, tpremiu_m, zile_intrerupere_teh_m,
		ind_intrerupere_tehnologica_m, ind_o_regim_normal, tdiminuari_m, co_necuvenit_stoehr,
		baza_comision, total_zile_cm_unit_m, total_zile_cm_cas_m, total_zile_cm_fambp_m, corectii,
		cod_numeric_personal, somaj_1, nr_contract, cod_cor, den_cor
	from #de_regrupat*/
		
	if object_id('tempdb..#brut1') is not null drop table #brut1
	if object_id('tempdb..#de_regrupat') is not null drop table #de_regrupat

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapStatDePlataDirectaMuncii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
