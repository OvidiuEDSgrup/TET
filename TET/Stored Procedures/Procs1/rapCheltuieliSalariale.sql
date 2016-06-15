/**	procedura pentru raportul de cheltuieli salariale */
Create procedure rapCheltuieliSalariale
	(@dataJos datetime, @dataSus datetime, @locm varchar(9)=null, @strict int=0, @centrucost varchar(6)=null, @grcentrucost varchar(6)=null, 
	@sircentrucost varchar(6)=null, @sircentrucostexcep varchar(6)=null, @functie char(6)=null, @marca char(6)=null, @grmarca char(6)=null, 
	@categsal char(4)=null, @grupamunca char(1)=null, @tippersonal char(1)=null, @sex int, @tipstat varchar(30)=null, 
	@salarincJos float, @salarincSus float, @salarnetJos float, @salarnetSus float, @notecontabile int, @nivel int, @listaDrept char(1), @ordonare int,
	@setlm varchar(20)=null, -->	set de locuri de munca (proprietate TIPBALANTA) 
	@centralizat int=0
	)
as
/*
	ordonare = 0 -> Locuri de munca, marci
	ordonare = 1 -> Locuri de munca, nume
	ordonare = 2 -> Centre de cost
	
	centrps = 1 -> centralizare pe loc de munca/centru de cost
	centrps = 2 -> centralizare pe loc de munca/marca
*/
begin try
	set transaction isolation level read uncommitted
	declare @somajTehnic int, @dreptConducere int, @optichm int, @tichetePersonalizate int, @valoaretichet float, @liste_drept char(1), @areDreptCond int, @Remarul int

	set @somajTehnic=dbo.iauParLL(@dataSus,'PS','STOUG28')
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @optichm = dbo.iauParL('PS','OPTICHINM')
	set @tichetePersonalizate=dbo.iauParL('PS','TICHPERS')
	set @valoaretichet = dbo.iauParLN(@dataSus,'PS','VALTICHET')
	set @Remarul=dbo.iauParL('SP','REMARUL')

	declare @utilizator varchar(20)
	set @utilizator = dbo.fIaUtilizator('')
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @liste_drept=@listaDrept
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @liste_drept='S'
	end
	
	if object_id('tempdb..#tmpchelt') is not null drop table #tmpchelt
	if object_id('tempdb..#cheltsal') is not null drop table #cheltsal
	if object_id('tempdb..#diurneNeimp') is not null drop table #diurneNeimp

	select b.data, b.marca, sum(b.ind_c_medical_cas+b.cmcas) as cm_fnuass, sum(b.spor_cond_9) as cm_fambp, sum(b.ind_c_medical_unitate+b.cmunitate) as cm_unitate, 
	sum(b.suma_impozabila) as suma_impozabila, sum(b.cons_admin) as cons_admin, sum((case when @somajTehnic=1 then b.Ind_invoiri else 0 end)) as Somaj_tehnic_marca 
	into #tmpchelt
	from brut b 
		left outer join net n on b.data = n.data and b.marca = n.marca
	where b.data between @dataJos and @dataSus 
		and (@locm is null or (case when @notecontabile=1 then b.loc_de_munca else n.loc_de_munca end) like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
	group by b.data, b.marca 
	order by b.data, b.marca

	select Data, Marca, Loc_de_munca, Suma_corectie as diurna_neimpozabila
	into #diurneNeimp
	from dbo.fSumeCorectie (@dataJos, @dataSus, 'W-', @Marca, @locm, 0) 

	select n.data as data, ltrim(rtrim(n.marca)) as marca, ltrim(rtrim(i.nume)) as nume, 
	(case when @notecontabile=1 and @ordonare<>2 then b.loc_de_munca when @notecontabile=0 and @ordonare<>2 then n.loc_de_munca else e.marca end) as lm, 
	(case when @ordonare<>2 then lm.denumire else e.comanda end) as den_lm, 
	(case when @notecontabile=1 or @ordonare=2 then b.venit_total else 0 end) as venit_total_brut, 
	p.somaj_1 as somaj_1_pers, i.loc_de_munca as lm_istpers, i.cod_functie, f.denumire as den_functie, 
	i.salar_de_incadrare, i.grupa_de_munca, i.mod_angajare, n.venit_total as venit_total_net, 0 as venit_total, 
	n.pensie_suplimentara_3, n.somaj_1, n.impozit, n.asig_sanatate_din_impozit, n.asig_sanatate_din_net, 
	(case when year(n.data)<2006 then n.asig_sanatate_din_CAS else 0 end) as asig_sanatate_din_CAS, 
	n.cas+isnull(n1.cas,0) as cas, n.somaj_5, n.fond_de_risc_1, n.Camera_de_Munca_1, n.asig_sanatate_pl_unitate, 
	(case when year(n.data)>=2006 then n.ded_suplim else 0 end) as cci, isnull(n1.somaj_5,0) as fond_garantare,
	(case when @notecontabile=1 then b.Ind_c_medical_CAS+b.CMCAS else t.cm_fnuass end) as cm_fnuass, 
	(case when @notecontabile=1 then b.Spor_cond_9 else t.cm_fambp end) as cm_fambp, 
	(case when @notecontabile=1 then b.Ind_c_medical_unitate+b.CMunitate else t.cm_unitate end) as cm_unitate, 
	b.Ind_c_medical_CAS+b.CMCAS as cm_fnuass_pozitie, b.Spor_cond_9 as cm_fambp_pozitie, b.Ind_c_medical_unitate+b.CMunitate as cm_unitate_pozitie, 
	t.cm_fnuass as cm_fnuass_marca, t.cm_fambp as cm_fambp_marca, t.cm_unitate as cm_unitate_marca, 
	n.venit_net, 
	isnull((case when @optichm=0 then (select sum(ore__cond_6) from pontaj o where o.data between dbo.bom(n.Data) and n.Data and o.marca=n.marca) 
	else (select sum(nr_tichete) from tichete t where t.data_lunii=n.data and t.marca=n.marca 
		and (@tichetePersonalizate=1 and (t.Tip_operatie in ('C','S','R') or @Remarul=0 and t.Tip_operatie='P')
		or @tichetePersonalizate=0 and (t.Tip_operatie in ('P','S','C') or tip_operatie='R' and valoare_tichet<>0))) end),0) as nr_tichete, 
	isnull((case when @optichm=0 then (select sum(ore__cond_6)*dbo.iauParLN(n.data,'PS','VALTICHET') from pontaj o where o.data between dbo.bom(n.Data) and n.Data and o.marca=n.marca) 
		else (select sum(t.nr_tichete*t.valoare_tichet) from tichete t where t.data_lunii=n.data and t.marca=n.marca 
		and (@tichetePersonalizate=1 and (t.Tip_operatie in ('C','S','R') or @Remarul=0 and t.Tip_operatie='P')
		or @tichetePersonalizate=0 and (t.Tip_operatie in ('P','S','C') or tip_operatie='R' and valoare_tichet<>0))) end),0) as valoare_tichete,  
	(case when @somajTehnic=1 then b.Ind_invoiri else 0 end) as Somaj_tehnic_pozitie, t.Somaj_tehnic_marca as Somaj_tehnic_marca, 
	t.suma_impozabila, t.cons_admin, isnull(dn.diurna_neimpozabila,0) as diurna_neimpozabila, 
	convert(float,0) as Procent, convert(float,0) as ProcentITM, convert(decimal(12,2),0) as chelt_sal, convert(decimal(12,2),0) as total_chelt, 
	(case when @ordonare=2 then e.marca else '' end)+(case when @notecontabile=1 or @ordonare=2 then b.loc_de_munca else n.loc_de_munca end) +(case when @ordonare=1 then p.nume else n.marca end) as ordonare
	into #cheltsal1
	from net n 
		left outer join personal p on n.marca=p.marca
		left outer join brut b on n.data=b.data and n.marca=b.marca 
		left outer join infopers d on n.marca=d.marca
		left outer join lm on lm.Cod=(case when @notecontabile=1 then b.loc_de_munca else n.loc_de_munca end)
		left outer join speciflm e on b.loc_de_munca=e.loc_de_munca
		left outer join functii f on p.cod_functie=f.cod_functie
		left outer join net n1 on dbo.bom(n.data) = n1.data and n.marca=n1.marca 
		left outer join istpers i on n.data=i.data and n.marca=i.marca 
		left outer join #tmpchelt t on n.data=t.data and n.marca=t.marca
		left outer join #diurneNeimp dn on n.data=dn.data and n.marca=dn.marca
	where n.data between @dataJos and @dataSus and n.data=dbo.eom(n.data) 
		and (@locm is null or (case when @notecontabile=1 then b.loc_de_munca else n.loc_de_munca end) like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (@ordonare<>2 or (@centrucost is null or e.marca like rtrim(@centrucost)+'%'))
		and (@ordonare<>2 or (@grcentrucost is null or e.marca like rtrim(@grcentrucost)+'%'))
		and (@ordonare<>2 or (@sircentrucost is null or (charindex(','+rtrim(e.marca)+',',@sircentrucost)>0)))
		and (@ordonare<>2 or (@sircentrucostexcep is null or (charindex(','+rtrim(e.marca)+',',@sircentrucostexcep)=0)))
		and (@marca is null or n.marca=@marca)
		and (@functie is null or i.cod_functie=@functie)
		and (@grupamunca is null or i.Grupa_de_munca=@grupamunca)
		and (@tippersonal is null or (@tippersonal='T' and i.tip_salarizare in ('1','2')) or (@tippersonal='M' and i.tip_salarizare in ('3','4','5','6','7'))) 
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@liste_drept='T' or @liste_drept='C' and p.pensie_suplimentara=1 or @liste_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @liste_drept='S' and p.pensie_suplimentara<>1))
		and (@tipstat is null or d.religia=@tipstat)
		and (@sex is null or p.sex=@sex)
		and (@salarincJos is null or i.Salar_de_incadrare between @salarincJos and @salarincSus)
		and (@salarnetJos is null or n.VENIT_NET between @salarnetJos and @salarnetSus)
		and (@categsal is null or i.Categoria_salarizare=@categsal)
		and (dbo.f_areLMFiltru(@utilizator)=0 
			or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=(case when @notecontabile=1 then b.loc_de_munca else n.loc_de_munca end)))
		and (@setlm is null 
			or exists (select 1 from proprietati pr where pr.Cod_proprietate='TIPBALANTA' and pr.Tip='LM' and pr.Valoare=@setlm and rtrim(n.Loc_de_munca) like rtrim(pr.cod)+'%'))
	order by ordonare, n.data

-->	calculez procent de repartizare pe locuri de munca de cheltuiala
	update #cheltsal1 set Procent=(case when venit_total_brut>0 then (venit_total_net-Somaj_tehnic_marca)/(venit_total_brut-Somaj_tehnic_pozitie) else 1 end),
	ProcentITM=(case when venit_total_brut-(cm_fambp_pozitie+cm_fnuass_pozitie)>0 
		then (venit_total_net-(cm_fambp_marca+cm_fnuass_marca))/(venit_total_brut-(cm_fambp_pozitie+cm_fnuass_pozitie)) else 1 end),
	chelt_sal=venit_net-cm_fnuass+pensie_suplimentara_3+somaj_1+impozit+asig_sanatate_din_net+cas+somaj_5+fond_de_risc_1+cci+asig_sanatate_pl_unitate+fond_garantare

	update #cheltsal1 set venit_total=(case when @notecontabile=1 then venit_total_brut else venit_total_net end), 
		Pensie_suplimentara_3=(case when @notecontabile=1 then round(Pensie_suplimentara_3/Procent,2) else Pensie_suplimentara_3 end), 
		Somaj_1=(case when @notecontabile=1 then round(Somaj_1/Procent,2) else Somaj_1 end), 
		Asig_sanatate_din_net=(case when @notecontabile=1 then round(Asig_sanatate_din_net/Procent,2) else Asig_sanatate_din_net end), 
		Impozit=(case when @notecontabile=1 then round(Impozit/Procent,2) else Impozit end), 
		cas=round((case when @notecontabile=1 then round(cas/Procent,2) else cas end),2), 
		Somaj_5=round((case when @notecontabile=1 then round(Somaj_5/Procent,2) else Somaj_5 end),2), 
		Fond_de_risc_1=round((case when @notecontabile=1 then round(Fond_de_risc_1/Procent,2) else Fond_de_risc_1 end),2), 
		cci=round((case when @notecontabile=1 then round(cci/Procent,2) else cci end),2), 
		Camera_de_Munca_1=round((case when @notecontabile=1 then round(Camera_de_Munca_1/ProcentITM,2) else Camera_de_Munca_1 end),2), 
		Asig_sanatate_pl_unitate=round((case when @notecontabile=1 then round(Asig_sanatate_pl_unitate/Procent,2) else Asig_sanatate_pl_unitate end),2), 
		fond_garantare=round((case when @notecontabile=1 then round(fond_garantare/Procent,2) else fond_garantare end),2), 
		venit_net=(case when @notecontabile=1 then round(venit_net/ProcentITM,0) else venit_net end),
		nr_tichete=(case when @notecontabile=1 then round(nr_tichete/Procent,2) else nr_tichete end),
		valoare_tichete=(case when @notecontabile=1 then round(valoare_tichete/Procent,2) else valoare_tichete end),
		diurna_neimpozabila=(case when @notecontabile=1 then round(diurna_neimpozabila/Procent,2) else diurna_neimpozabila end),
		chelt_sal=(case when @notecontabile=1 then round(chelt_sal/Procent,2)+ROUND(Camera_de_Munca_1/ProcentITM,2) else chelt_sal+Camera_de_Munca_1 end)

-->	calculez total cheltuieli
	update #cheltsal1 set total_chelt=chelt_sal+valoare_tichete

-->	calculez total valoare tichete cu valoare diurna neimpozabila. 
-->	Am pus in acest loc update-ul pe valoare tichete si nu deasupra celui anterior intrucat diurna neimpozabila este inclusa deja in venitul net si implicit in total cheltuieli
	update #cheltsal1 set valoare_tichete=valoare_tichete+diurna_neimpozabila

	select data, marca, max(nume) as nume, (case when @ordonare=2 and @nivel>0 then left(lm,@nivel) else lm end) as lm, max(den_lm) as den_lm, 
		max(cod_functie) as cod_functie, max(den_functie) as den_functie, max(somaj_1_pers) as somaj_1_pers, max(lm_istpers) as lm_istpers, 
		max(grupa_de_munca) as grupa_de_munca, max(mod_angajare) as mod_angajare, 
		max(salar_de_incadrare) as salar_de_incadrare, max(venit_total) as venit_total, 
		max(pensie_suplimentara_3) as pensie_suplimentara_3, max(somaj_1) as somaj_1, max(impozit) as impozit, max(asig_sanatate_din_impozit) as asig_sanatate_din_impozit, 
		max(asig_sanatate_din_net) as asig_sanatate_din_net, max(asig_sanatate_din_CAS) as asig_sanatate_din_CAS, 
		max(CAS) as cas, max(somaj_5) as somaj_5, max(fond_de_risc_1) as fond_de_risc_1, max(Camera_de_Munca_1) as Camera_de_Munca_1, 
		max(asig_sanatate_pl_unitate) as asig_sanatate_pl_unitate, max(CCI) as cci, max(fond_garantare) as fond_garantare, 
		max(cm_fnuass) as cm_fnuass, max(cm_fambp) as cm_fambp, max(cm_fambp+cm_fnuass) as cm_stat, max(cm_unitate) as cm_unitate, max(venit_net) as venit_net, max(suma_impozabila) as suma_impozabila, max(cons_admin) as cons_admin, 
		max(nr_tichete) as nr_tichete, max(valoare_tichete) as valoare_tichete, max(round(chelt_sal,0)) as chelt_sal, max(round(total_chelt,0)) as total_chelt, 
		max(venit_total-(cm_fambp+cm_fnuass)) as Venit_total_fara_cmstat, ordonare
	into #cheltsal
	from #cheltsal1
	group by (case when @ordonare=3 then convert(char(10),Data,104) else lm end), 
		(case when @ordonare=3 then lm when  @ordonare=1 then nume else Marca end), data, marca, lm, ordonare

	if exists (select * from sysobjects where name ='rapCheltuieliSalarialeSP' and xtype='P')
		exec rapCheltuieliSalarialeSP @dataJos, @dataSus, @locm, @strict, @centrucost, @grcentrucost, @sircentrucost, @sircentrucostexcep, @functie, @marca, @grmarca, 
				@categsal, @grupamunca, @tippersonal, @sex, @tipstat, @salarincJos, @salarincSus, @salarnetJos, @salarnetSus, @notecontabile, @nivel, @listaDrept, @ordonare, @setlm, @centralizat

	select data, marca, nume, lm, den_lm, 
		cod_functie, den_functie, somaj_1_pers, lm_istpers, grupa_de_munca, mod_angajare, 
		salar_de_incadrare, venit_total, pensie_suplimentara_3, somaj_1, impozit, asig_sanatate_din_impozit, 
		asig_sanatate_din_net, asig_sanatate_din_CAS, cas, somaj_5, fond_de_risc_1, Camera_de_Munca_1, 
		asig_sanatate_pl_unitate, cci, fond_garantare, cm_fnuass, cm_fambp, cm_stat, cm_unitate, venit_net, suma_impozabila, cons_admin, 
		nr_tichete, valoare_tichete, chelt_sal, total_chelt, Venit_total_fara_cmstat, ordonare
	from #cheltsal
	order by (case when @ordonare=3 then convert(char(10),data,104) else lm end), 
		(case when @ordonare=3 then lm when  @ordonare=1 then nume else marca end), data, marca, lm, ordonare

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapCheltuieliSalariale (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#tmpchelt') is not null drop table #tmpchelt
if object_id('tempdb..#cheltsal1') is not null drop table #cheltsal1
if object_id('tempdb..#cheltsal') is not null drop table #cheltsal

/*
	exec rapCheltuieliSalariale '03/01/2012', '03/31/2012', '109', 0, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, 0, 'T', 1
*/
