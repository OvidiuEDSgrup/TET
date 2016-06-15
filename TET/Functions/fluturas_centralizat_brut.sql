--***
/**	fluturas centralizat pe brut	*/
Create function fluturas_centralizat_brut
	(@dataJos datetime, @dataSus datetime, @MarcaJ char(6), @MarcaS char(6), @LocmJ char(9), @LocmS char(9), 
	@lGrupaM int, @cGrupaM char(1), @lTipSalarizare int, @cTipSalJos char(1), @cTipSalSus char(1), @lTipPers int, @cTipPers char(1), 
	@lFunctie int, @cFunctie char(6), @lMandatar int,@cMandatar char(6),@lCard int, @cCard char(30), @lUnSex int, @Sex int, 
	@lTipStat int, @cTipStat char(200),@AreDreptCond int,@cListaCond char(1),@lTipAngajare int, @cTipAngajare char(1), 
	@lSirMarci int, @cSirMarci char(200), @LmExcep char(9), @StrictLmExcep int, @lGrupaMuncaExcep int, 
	@exclLM varchar(20)=null, @setlm varchar(20)=null, @activitate varchar(20)=null)
returns @fluturas_centralizat_brut table
	(Data datetime, Marca char(6), Total_ore_lucrate int, Ore_lucrate__regie int, Realizat__regie float, Ore_lucrate_acord float, Realizat_acord float, 
	Ore_supl_1 int, Ind_ore_supl_1 float, Ore_supl_2 int, Ind_ore_supl_2 float, Ore_supl_3 float, Ind_ore_supl_3 float, Ore_supl_4 int, Ind_ore_supl_4 float, 
	Ore_spor_100 int, Indemnizatie_ore_spor_100 float, Ore_de_noapte int, Ind_ore_de_noapte float, Ore_lucrate_regim_normal int, Ind_regim_normal float, 
	Ore_intrerupere_tehnologica int, Ind_intrerupere_tehnologica float, Ore_obligatii_cetatenesti int, Ind_obligatii_cetatenesti float, 
	Ore_concediu_fara_salar int, Ind_concediu_fara_salar float, Ore_concediu_de_odihna int, Ind_concediu_de_odihna float, 
	Ore_concediu_medical int, Ind_c_medical_unitate float, Ind_c_medical_CAS float, CMFAMBP float, Ore_invoiri int, Ind_intrerupere_tehnologica_2 float, 
	Ore_nemotivate int, Ind_conducere float, Salar_categoria_lucrarii float, 
	CMCAS float, CMunitate float, CO float, Restituiri float, Diminuari float, Suma_impozabila float, Premiu float, Diurna float, Cons_admin float, 
	Sp_salar_realizat float, Suma_imp_separat float,Premiu2 float, Diurna2 float, CO2 float, Avantaje_materiale float, Avantaje_impozabile float, 
	Spor_vechime float, Spor_de_noapte float, Spor_sistematic_peste_program float, Spor_de_functie_suplimentara float, Spor_specific float, 
	Spor_cond_1 float, Spor_cond_2 float, Spor_cond_3 float, Spor_cond_4 float, Spor_cond_5 float, Spor_cond_6 float, 
	Aj_deces float, Venit_total float, Spor_cond_7 float, Spor_cond_8 float, ore_intr_tehn_1 int, ore_intr_tehn_2 int, ore_intr_tehn_3 int, Cor_U float, Cor_W float, 
	Deplasari_RN float, Numar_mediu_salariati float, Baza_CASS_AMBP float,salar_de_incadrare float)
as
begin

	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)
	
	declare @Ore_luna float, @ldrept_conducere int, @SubtipCor int, @Colas int, @Grup7 int, @den_intr3 char(30)

	Set @Ore_luna=dbo.iauParN('PS','ORE_LUNA')
	Set @ldrept_conducere=dbo.iauParL('PS','DREPTCOND')
	Set @SubtipCor=dbo.iauParL('PS','SUBTIPCOR')
	Set @Colas=dbo.iauParL('SP','COLAS')
	Set @Grup7=dbo.iauParL('SP','GRUP7')
	Set @den_intr3=dbo.iauParA('PS','PROC3INT')

	insert @fluturas_centralizat_brut
	select a.data, a.marca, sum(a.Total_ore_lucrate) as Total_ore_lucrate, sum(a.Ore_lucrate__regie) as Ore_lucrate__regie, 
	sum(round(a.Realizat__regie,0)) as Realizat__regie, sum(a.Ore_lucrate_acord) as Ore_lucrate_acord, sum(a.Realizat_acord) as Realizat_acord, 
	sum(a.Ore_suplimentare_1) as Ore_suplimentare_1, sum(round(a.Indemnizatie_ore_supl_1,0)) as Indemnizatie_ore_supl_1, 
	sum(a.Ore_suplimentare_2) as Ore_suplimentare_2, sum(round(a.Indemnizatie_ore_supl_2,0)) as Indemnizatie_ore_supl_2, 
	sum(a.Ore_suplimentare_3) as Ore_suplimentare_3, sum(round(a.Indemnizatie_ore_supl_3,0)) as Indemnizatie_ore_supl_3, 
	sum(a.Ore_suplimentare_4) as Ore_suplimentare_4, sum(round(a.Indemnizatie_ore_supl_4,0)) as Indemnizatie_ore_supl_4, 
	sum(a.Ore_spor_100) as Ore_spor_100, sum(round(a.Indemnizatie_ore_spor_100,0)) as Indemnizatie_ore_spor_100, 
	sum(a.Ore_de_noapte) as Ore_de_noapte, sum(round(a.Ind_ore_de_noapte,0)) as Ind_ore_de_noapte, 
	sum(a.Ore_lucrate_regim_normal) as Ore_lucrate_regim_normal, sum(round(a.Ind_regim_normal,0)) as Ind_regim_normal, 
	sum(a.Ore_intrerupere_tehnologica) as Ore_intrerupere_tehnologica, sum(round(a.Ind_intrerupere_tehnologica,0)) as Ind_intrerupere_tehnologica, 
	sum(a.Ore_obligatii_cetatenesti) as Ore_obligatii_cetatenesti, sum(round(a.Ind_obligatii_cetatenesti,0)) as Ind_obligatii_cetatenesti, 
	sum(a.Ore_concediu_fara_salar) as Ore_concediu_fara_salar, sum(round(a.Ind_concediu_fara_salar,0)) as Ind_concediu_fara_salar, 
	sum(a.Ore_concediu_de_odihna) as Ore_concediu_de_odihna, sum(round(a.Ind_concediu_de_odihna,0)) as Ind_concediu_de_odihna, 
	sum(a.Ore_concediu_medical) as Ore_concediu_medical, sum(a.Ind_c_medical_unitate) as Ind_c_medical_unitate, 
	sum(a.Ind_c_medical_CAS) as Ind_c_medical_CAS, sum(a.spor_cond_9) as CMFAMBP, sum(a.Ore_invoiri) as Ore_invoiri, 
	sum(round(a.Ind_invoiri,0)) as Ind_intrerupere_tehnologica_2, sum(a.Ore_nemotivate) as Ore_nemotivate, 
	sum(a.Ind_nemotivate) as Ind_conducere, sum(a.Salar_categoria_lucrarii) as Salar_categoria_lucrarii, 
	sum(a.CMCAS) as CMCAS, sum(a.CMunitate) as CMunitate, sum(a.CO-isnull(z.Suma_corectie,0)) as CO, sum(a.Restituiri) as Restituiri, 
	sum(a.Diminuari) as Diminuari, sum(a.Suma_impozabila) as Suma_impozabila, sum(a.Premiu-isnull(x.Suma_corectie,0)) as Premiu, sum(a.Diurna-isnull(y.Suma_corectie,0)) as Diurna, 
	sum(a.Cons_admin) as Cons_admin, sum(a.Sp_salar_realizat) as Sp_salar_realizat, sum(a.Suma_imp_separat) as Suma_imp_separat, 
	sum(isnull(x.Suma_corectie,0)), sum(isnull(y.Suma_corectie,0)), sum(isnull(z.Suma_corectie,0)), sum(isnull(q.Suma_corectie,0)), sum(isnull(ai.Suma_corectie,0)), 
	sum(a.Spor_vechime) as Spor_vechime, sum(a.Spor_de_noapte) as Spor_de_noapte, 
	sum(a.Spor_sistematic_peste_program) as Spor_sistematic_peste_program, sum(a.Spor_de_functie_suplimentara) as Spor_de_functie_suplimentara, 
	sum(round(a.Spor_specific,0)) as Spor_specific, sum(round(a.Spor_cond_1,0)) as Spor_cond_1, sum(round(a.Spor_cond_2,0)) as Spor_cond_2, sum(round(a.Spor_cond_3,0)) as Spor_cond_3, 
	sum(round(a.Spor_cond_4,0)) as Spor_cond_4, sum(round(a.Spor_cond_5,0)) as Spor_cond_5, sum(round(a.Spor_cond_6,0)) as Spor_cond_6, sum(a.Compensatie) as Aj_deces, 
	sum(a.VENIT_TOTAL) as Venit_total, sum(round(a.Spor_cond_7,0)) as Spor_cond_7, sum(round(a.Spor_cond_8,0)) as Spor_cond_8, 
	isnull((select sum(j.ore_intrerupere_tehnologica) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0) as ore_intrerupere_tehnologica_1, 
	isnull((select sum(j.ore) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0) as ore_intrerupere_tehnologica_2, 
	(case when @Colas=1 or @den_intr3<>'' then isnull((select sum(j.spor_cond_8) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0) 
		else 0 end) as ore_intrerupere_tehnologica_2, 
	sum(isnull(u.Suma_corectie,0)) as Cor_U, sum(isnull(w.Suma_corectie,0)) as Cor_W, 
	round((select sum(pt.spor_cond_10) from pontaj pt where year(pt.data)=year(a.data) and month(pt.data)=month(a.data) and marca=a.marca)*max(a.salar_orar),0) as Deplasari_RN,
	sum(a.Ore_lucrate_regim_normal+a.Ore_concediu_de_odihna)/(case when dbo.iauParLN(a.Data,'PS','ORE_LUNA')=0 then @Ore_luna else dbo.iauParLN(a.Data,'PS','ORE_LUNA') end),
	isnull((select sum(indemnizatie_unitate) from conmed c 
		where year(c.data)=year(a.data) and month(c.data)=month(a.data) and c.marca=a.marca and c.tip_diagnostic in ('2-','3-','4-')),0) as Baza_CASS_AMBP,
	sum(i.salar_de_incadrare)
	from brut a
		left outer join personal p on p.marca=a.marca  
		left outer join infopers c on c.marca=a.marca  
		inner join istpers i on i.data=a.data and i.marca=a.marca  
		left outer join net n on n.data=a.data and n.marca=a.marca  
		left outer join mandatar m on m.loc_munca=a.loc_de_munca 
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', @MarcaJ, @LocmJ, 1) q on q.Data=a.Data and q.Marca=a.Marca and q.Loc_de_munca=a.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'X-', @MarcaJ, @LocmJ, 1) x on x.data=a.data and x.marca=a.marca and x.loc_de_munca=a.loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Y-', @MarcaJ, @LocmJ, 1) y on y.data=a.data and y.marca=a.marca and y.loc_de_munca=a.loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Z-', @MarcaJ, @LocmJ, 1) z on z.data=a.data and z.marca=a.marca and z.loc_de_munca=a.loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'U-', @MarcaJ, @LocmJ, 1) u on u.data=a.data and u.marca=a.marca and u.loc_de_munca=a.loc_de_munca and @Grup7=0
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'W-', @MarcaJ, @LocmJ, 1) w on w.data=a.data and w.marca=a.marca and w.loc_de_munca=a.loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'AI', @MarcaJ, @LocmJ, 1) ai on ai.data=a.data and ai.marca=a.marca and ai.loc_de_munca=a.loc_de_munca
	where a.data between @dataJos and @dataSus and (@MarcaJ='' or a.marca between @MarcaJ and @MarcaS) 
		and (@LocmJ='' or n.loc_de_munca between @LocmJ and @LocmS) 
		and (@lGrupaM=0 or (@lGrupaMuncaExcep=0 and i.grupa_de_munca=@cGrupaM or @lGrupaMuncaExcep=1 
		and i.grupa_de_munca<>@cGrupaM)) and (@lTipSalarizare=0 or i.tip_salarizare between @cTipSalJos and @cTipSalSus) 
		and (@lTipPers=0 or @cTipPers='N' and c.Actionar=1 or @cTipPers='C' and c.Actionar=0) and (@lFunctie=0 or i.cod_functie=@cFunctie) 
		and (@lMandatar=0 or m.mandatar=@cMandatar) and (@lCard=0 or p.banca=@cCard) 
		and (@lUnSex=0 or p.sex=@Sex) and (@lTipStat=0 or c.religia=@cTipStat) and (@ldrept_conducere=0 or (@AreDreptCond=1 
		and (@cListaCond='T' or @cListaCond='C' and p.pensie_suplimentara=1 or @cListaCond='S' and p.pensie_suplimentara<>1)) or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@lTipAngajare=0 or @cTipAngajare='P' and i.grupa_de_munca in ('N','D','S') or @cTipAngajare='O' and i.grupa_de_munca in ('O','C')) 
		and (@lSirMarci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@cSirMarci)>0) 
		and (@LmExcep='' or n.loc_de_munca not like rtrim(@LmExcep)+(case when @StrictLmExcep=1 then '' else '%' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=n.Loc_de_munca))
		and (@exclLM is null or not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='NUSTAT' and valoare=@exclLM and n.loc_de_munca=p.Cod))
		and (@setlm is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(n.Loc_de_munca) like rtrim(p.cod)+'%'))
		and (@activitate is null or p.Activitate=@activitate)
	group by a.marca, a.data
	return
end
