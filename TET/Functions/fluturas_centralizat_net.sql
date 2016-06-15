--***
/**	fluturas centralizat pe net	*/
Create function fluturas_centralizat_net
	(@dataJos datetime, @dataSus datetime, @MarcaJ char(6), @MarcaS char(6), @LocmJ char(9), @LocmS char(9), @lGrupaM int, @cGrupaM char(1),
	@lTipSalarizare int,@cTipSalJos char(1),@cTipSalSus char(1),@lTipPers int, @cTipPers char(1),@lFunctie int, @cFunctie char(6),@lMandatar int,@cMandatar char(6),@lCard int,@cCard char(30),
	@lUnSex int,@Sex int, @lTipStat int,@cTipStat char(200),@AreDreptCond int,@cListaCond char(1),@lTipAngajare int,@cTipAngajare char(1), 
	@lSirMarci int, @cSirMarci char(200), @LmExcep char(9),@StrictLmExcep int,@lGrupaMExcep int,@Grupare char(20), 
	@exclLM varchar(20)=null, @setlm varchar(20)=null, @activitate varchar(20)=null) 
returns @fluturas_centralizat_net table
	(Data datetime,Marca char(6),CM_incasat float,CO_incasat float,suma_incasata float,suma_neimpozabila float,Diferenta_impozit float,Impozit float,Impozit_ipotetic float,Pensie_suplimentara_3 float,
	Baza_somaj_1 float,Somaj_1 float,Asig_sanatate_din_impozit float,Asig_sanatate_din_net float, Asig_sanatate_din_CAS float,VENIT_NET float,Avans float,Premiu_la_avans float,
	Debite_externe float,Rate float,Debite_interne float,Cont_curent float,REST_DE_PLATA float,CAS_unitate float,Somaj_5 float,Fond_de_risc_1 float,Camera_de_Munca_1 float, 
	Asig_sanatate_pl_unitate float,CCI float,VEN_NET_IN_IMP float,Ded_personala float,Ded_pens_fac float,Venit_baza_imp float, Venit_baza_imp_scutit float, 
	Baza_CAS_ind float,Baza_CAS_cond_norm float,Baza_CAS_cond_deoseb float,Baza_CAS_cond_spec float, 
	Subv_somaj_art8076 float,Subv_somaj_art8576 float,Subv_somaj_art172 float,Subv_somaj_legea116 float,
	Baza_somaj_5 float,Baza_somaj_5_FP float, Baza_CASS_unitate float,Baza_CCI float,Baza_Camera_de_munca_1 float,Venit_pensionari_scutiri_somaj float,CCI_Fambp float,
	Baza_CAS_cond_norm_CM float,Baza_CAS_cond_deoseb_CM float,Baza_CAS_cond_spec_CM float,CAS_CM float,Baza_fgarantare float,Fond_garantare float,
	Baza_fambp_CM float, ven_ocazO float,ven_ocazP float,Ore_ingr_copil int,
	Nr_tichete float,Val_tichete float,NrTichSupl float,ValTichSupl float,Nr_tichete_acordate float,Val_tichete_acordate float, 
	Ajutor_ridicat_dafora float, Ajutor_cuvenit_dafora float,Prime_avans_dafora float,Avans_CO_dafora float,
	SPNedet int, SPDet int, Ocazional int,Ocaz_P int,Ocaz_P_AS2 int,Cm_t_part int, Handicap int,Angajat int,Plecat int,Plecat_01 int,NuSalariat int,Zilier int,
	Scut_art_80 float, Scut_art_85 float, Cotiz_hand float,CASS_AMBP float,Nrms_cnph float,Virament_partial float,cas_de_virat float, 
	fondrisc_de_virat float, CMUnit30Z float, VenitZilieri float, ImpozitZilieri float, RestPlataZilieri float)
as
begin
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)
	
	declare @ajdecunit bit,@lDreptCond int,@Buget int,@CMunitSomaj int,@NuCAS_H int,@CMunitCASS int,@NuCASS_H int,
		@CMunitITM int,@Cassimps_K int,@CMstatFG int,@CMunitFG int,@coefCCI float,@Dafora int,
		@lOPTICHINM int,@lNC_tichete int, @lTichete_personalizate int, @nTabela int, @cTabela char(1), 
		@Val_tichet float, @nVal_tichet float, @ImpozitTichete int, @DataTicJ datetime, @DataTicS datetime, 
		@NCCnph int, @ContributieNPH decimal(12,2), @Numar_mediu_cnph decimal(10,2)
	Set @ajdecunit=dbo.iauParL('PS','AJDUNIT-R')
	Set @lDreptCond=dbo.iauParL('PS','DREPTCOND')
	Set @Buget=dbo.iauParL('PS','UNITBUGET')
	Set @Dafora=dbo.iauParL('SP','DAFORA')
	Set @CMunitSomaj=dbo.iauParL('PS','CM-SC-S5%')
	Set @CMunitCASS=dbo.iauParL('PS','CM-SC-F7%')
	Set @CMunitITM=dbo.iauParL('PS','CM-SC-CM1')
	Set @CMstatFG=dbo.iauParL('PS','CM-ST-FG')
	Set @CMunitFG=dbo.iauParL('PS','CM-SC-FG')
	Set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
	Set @NuCASS_H=dbo.iauParL('PS','NUASS-H')
	Set @Cassimps_K=dbo.iauParL('PS','ASSIMPS-K')
------------	fluturas_centralizat_net1:	
	Set @lOPTICHINM = dbo.iauParL('PS','OPTICHINM')
	Set @lNC_tichete = dbo.iauParL('PS','NC-TICHM')
	Set @lTichete_personalizate = dbo.iauParL('PS','TICHPERS')
	Set @nTabela = dbo.iauParN('PS','NC-TICHM')
	Set @cTabela = (case when convert(char(2),@nTabela)>1 then right(rtrim(convert(char(2),@nTabela)),1) else '' end)
	Set @nVal_tichet = dbo.iauParN('PS','VALTICHET')
	Set @ImpozitTichete=dbo.iauParLL(@dataSus,'PS','DJIMPZTIC')
	Set @DataTicJ=dbo.iauParLD(@dataSus,'PS','DJIMPZTIC')
	Set @DataTicS=dbo.iauParLD(@dataSus,'PS','DSIMPZTIC')
	Set @DataTicJ=(case when @DataTicJ='01/01/1901' then @dataJos else @DataTicJ end)
	Set @DataTicS=(case when @DataTicS='01/01/1901' then @dataSus else @DataTicS end)
	Set @NCCnph=dbo.iauParL('PS','NC-CPHAND') 
	if @NCCnph=1 and dbo.eom(@dataJos)=@dataSus 
		select @ContributieNPH=isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'CPH'+'%'
				and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
				and (@Grupare in ('AN','LUNA','MARCA') and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102))=@dataSus or @Grupare='' 
				and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @dataJos and @dataSus)),0)
	if @NCCnph=1 and @LocmJ<>'' and dbo.eom(@dataJos)=@dataSus 
		and @ContributieNPH<>0	-- doar daca s-a calculat contributia per total unitate are sens sa o calculam si la filtrare pe loc de munca
		select @ContributieNPH=Suma_cnph, @Numar_mediu_cnph=Numar_mediu_cnph
			from dbo.fCalcul_cnph (@dataJos, @dataSus, '', @LocmJ, @LocmS, '', null, null)
	Select @ContributieNPH=ISNULL(@ContributieNPH,0), @Numar_mediu_cnph=ISNULL(@Numar_mediu_cnph,0)

	declare @fluturas_centralizat_net1 table
		(Data datetime,Marca char(6),Avans float,Premiu_av float,Ajutor_ridicat_dafora float,Ajutor_cuvenit_dafora float,Prime_avans_dafora float, Avans_CO_dafora float,Ore_ingr_copil int,
		Ingrij_copil int,Nr_tichete float,Val_tichete float,NrTichSupl float,ValTichSupl float,Nr_tichete_acordate float,Val_tichete_acordate float, 
		SPNedet int,SPDet int,Ocazional int,Ocaz_P int,Ocaz_P_AS2 int,Cm_t_part int,Handicap int,
		Angajat int,Plecat int,Plecat_01 int,scut_80 float,Scut_85 float, Cotiz_hand float,Nrms_cnph float)

	insert into @fluturas_centralizat_net1
	select a.data,a.marca,
	sum(a.Avans-(case when a.Premiu_la_avans<>0 then 0 else isnull(x.Premiu_la_avans,0) end)),
	sum((case when a.Premiu_la_avans<>0 then a.Premiu_la_avans else isnull(x.Premiu_la_avans,0) end)),
	isnull((select sum(co.suma_corectie) from corectii co where @Dafora=1 and year(co.data)=year(a.Data) and month(co.data)=month(a.Data) 
		and co.Marca=a.Marca and co.tip_corectie_venit='S-'),0),
	isnull((select sum(co.suma_corectie) from corectii co where @Dafora=1 and year(co.data)=year(a.Data) and month(co.data)=month(a.Data) 
		and co.Marca=a.Marca and co.tip_corectie_venit in ('S-','F-')),0), 
	isnull((select sum(r.retinut_la_avans+r.retinut_la_lichidare) from resal r where @Dafora=1 and r.Data=a.Data and r.marca=a.marca and r.cod_beneficiar='11'),0),
	isnull((select sum(r.retinut_la_avans+r.retinut_la_lichidare) from resal r where @Dafora=1 and r.Data=a.Data and r.marca=a.marca and r.cod_beneficiar='10'),0),
	isnull((select sum(zile_lucratoare*8) from conmed cm where cm.Data=a.Data and cm.Tip_diagnostic='0-' and cm.Marca=a.Marca),0), 
	(case when isnull((select sum(zile_lucratoare*8) from conmed cm where cm.Data=a.Data and cm.Tip_diagnostic='0-' and cm.Marca=a.Marca),0)=0 then 0 else 1 end), 
	(case when a.Data>'06/30/2010' then isnull((select numar_tichete from fNC_tichete (dbo.iauParLD(a.Data,'PS','DJIMPZTIC'), dbo.iauParLD(a.Data,'PS','DSIMPZTIC'), a.Marca, 1)),0)
	when not(@lOPTICHINM=1 or @lNC_tichete=1 and @cTabela='2') 
	then isnull((select sum(j.ore__cond_6) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0) else sum(isnull(t.Nr_tichete,0)) end), 
	round((case when a.Data>'06/30/2010' then isnull((select Valoare_tichete from fNC_tichete (dbo.iauParLD(a.Data,'PS','DJIMPZTIC'), dbo.iauParLD(a.Data,'PS','DSIMPZTIC'), a.Marca, 1)),0)
	when not(@lOPTICHINM=1 or @lNC_tichete=1 and @cTabela='2') 
		then isnull((select sum(j.ore__cond_6) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0)
		*(case when isnull(max(l.Val_numerica),0)=0 then @nVal_tichet else isnull(max(l.Val_numerica),0) end) else sum(isnull(t.Val_tichete,0)) end),2), 
	sum(isnull(ts.NrTichSupl,0)),sum(isnull(ts.ValTichSupl,0)),
	sum((case when dbo.iauParLD(a.Data,'PS','DSIMPZTIC')<>a.Data then isnull(tc.Numar_tichete,0) else 0 end)) as Nr_tichete_acordate,
	sum((case when dbo.iauParLD(a.Data,'PS','DSIMPZTIC')<>a.Data then isnull(tc.Valoare_tichete,0) else 0 end)) as Val_tichete_acordate,
	(case when (max(i.mod_angajare)='N' or max(i.mod_angajare)='') and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
	(case when (max(i.mod_angajare) in ('D','R')) and max(i.grupa_de_munca)<>'O' then 1 else 0 end), 
	(case when max(i.grupa_de_munca)='O' then 1 else 0 end),(case when max(i.grupa_de_munca)='P' then 1 else 0 end),
	(case when max(i.grupa_de_munca)='P' and max(i.Tip_colab)='AS2' then 1 else 0 end),
	(case when max(i.grupa_de_munca)='C' then 1 else 0 end),(case when max(i.grad_invalid) in ('1','2','3') and max(i.grupa_de_munca)<>'O' then 1 else 0 end), 
	(case when year(max(p.Data_angajarii_in_unitate))=year(a.Data) and month(max(p.Data_angajarii_in_unitate))=month(a.Data) and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
	(case when max(convert(char(1),p.Loc_ramas_vacant))='1' and year(max(p.Data_plec))=year(a.Data) and month(max(p.Data_plec))=month(a.Data) and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
	(case when max(convert(char(1),p.Loc_ramas_vacant))='1' and year(max(p.Data_plec))=year(a.Data) and month(max(p.Data_plec))=month(a.Data) and day(max(p.Data_plec))=1 
		and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
	/*isnull((select count(1) from istpers i1 where i1.data between @dataJos and @dataSus 
	and (@MarcaJ='' or i1.marca between @MarcaJ and @MarcaS) and (@LocmJ='' or i1.loc_de_munca between @LocmJ and @LocmS)
	and year(i1.Data_plec)=year(a.Data) and month(i1.Data_plec)=month(a.Data) and day(i1.Data_plec)=1 and i1.grupa_de_munca<>'O'),0), */
	round(sum(isnull(ss.Scutire_art80,0)),0), round(sum(isnull(ss.Scutire_art85,0)),0), 
	(case when @NCCnph=1 and @LocmJ<>'' and dbo.eom(@dataJos)=@dataSus then @ContributieNPH else 
	isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'CPH'+'%'
	and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
	and (@Grupare in ('AN','LUNA','MARCA') and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102))=a.data or @Grupare='' 
		and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @dataJos and @dataSus)),0) end), 
	(case when @NCCnph=1 and @LocmJ<>'' and dbo.eom(@dataJos)=@dataSus then @Numar_mediu_cnph else 
	isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'NRM'+'%'
	and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
	and (@Grupare in ('AN','LUNA','MARCA') and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102))=a.data 
		or @Grupare='' and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @dataJos and @dataSus)),0) end)
	from net a
		left outer join (select data, marca, sum(ind_c_medical_unitate) as ind_c_medical_unitate 
			from brut where data between @dataJos and @dataSus group by data, marca) b on a.data=b.data and a.marca=b.marca
		left outer join extinfop e on e.marca=a.marca and e.cod_inf='DEXPSOMAJ'
		left outer join extinfop f on f.marca=a.marca and f.cod_inf='DCONVSOMAJ'
		left outer join personal p on p.marca=a.marca
		left outer join infopers c on c.marca=a.marca
		left outer join avexcep x on x.data=a.data and x.marca=a.marca   
		inner join istpers i on i.data=a.data and i.marca=a.marca   
		left outer join (select Data_lunii, Marca, sum((case when tip_operatie='R' then -1 else 1 end)*nr_tichete) as nr_tichete, 
		sum((case when tip_operatie='R' then -1 else 1 end)*nr_tichete*valoare_tichet) as Val_tichete from tichete 
		where Data_lunii between @dataJos and @dataSus and (@lTichete_personalizate=1 and tip_operatie in ('C','S','R') 
			or @lTichete_personalizate=0 and (tip_operatie in ('P','S') or tip_operatie='R' and valoare_tichet<>0)) group by Data_lunii, Marca) t on t.Data_lunii=a.Data and t.Marca=a.Marca
		left outer join (select Data_lunii, Marca, sum(nr_tichete) as NrTichSupl, sum(nr_tichete*valoare_tichet) as ValTichSupl from tichete 
			where Data_lunii between @dataJos and @dataSus and tip_operatie='S' group by Data_lunii, Marca) ts on ts.Data_lunii=a.Data 
		and ts.Marca=a.Marca
		left outer join fNC_tichete (@dataJos, @dataSus, @MarcaJ, 1) tc on tc.Data=a.Data and tc.Marca=a.Marca
		left outer join par_lunari l on l.data=a.data and l.tip='PS' and l.parametru='VALTICHET'   
		left outer join dbo.fScutiriSomaj (@dataJos, @dataSus, @MarcaJ, @MarcaS, @LocmJ, @LocmS) ss on ss.data=a.data and ss.marca=a.marca
	where a.data between @dataJos and @dataSus and a.data=dbo.eom(a.data)
		and (@MarcaJ='' or a.marca between @MarcaJ and @MarcaS) 
		and (@LocmJ='' or a.loc_de_munca between @LocmJ and @LocmS)
		and (@lTipPers=0 or @cTipPers='N' and c.Actionar=1 or @cTipPers='C' and c.Actionar=0) and (@lTipStat=0 or c.religia=@cTipStat) 
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=a.Loc_de_munca))
		and (@exclLM is null or not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='NUSTAT' and valoare=@exclLM and a.loc_de_munca=p.Cod))
		and (@activitate is null or p.Activitate=@activitate)
	group by a.Data,a.Marca

	declare @impozitIpotetic table (data datetime, marca varchar(6), impozitIpotetic varchar(100))

-->	selectez din extinfop, pozitia pentru salariatii care au impozit ipotetic (HG84/2013) valabila la data declaratiei. Acest impozit ipotetic nu trebuie cuprins in D112.

	insert into @impozitIpotetic
	select data, marca, impozitIpotetic 
	from dbo.fSalariatiCuImpozitIpotetic (@dataJos, @dataSus, @LocmJ, @MarcaJ) a
	where exists (select 1 from @fluturas_centralizat_net1 n1 where n1.data=a.data and n1.marca=a.marca)

----------*/
	Set @coefCCI=isnull((select val_numerica from par where tip_parametru='PS' and parametru='COEFCCI')/1000000,1)
	insert @fluturas_centralizat_net
	select a.data,a.marca,sum(a.CM_incasat),sum((case when @Dafora=1 then e.Avans_CO_dafora else a.CO_incasat end)), 
	sum(a.Suma_incasata-(case when @Dafora=1 then e.Ajutor_ridicat_dafora else 0 end)),
	sum(a.Suma_neimpozabila),sum(a.Diferenta_impozit),sum(a.Impozit),sum(case when upper(isnull(ii.impozitIpotetic,''))='DA' then a.Impozit else 0 end) as Impozit_ipotetic,
	sum(a.Pensie_suplimentara_3),sum((case when a.somaj_1<>0 then a.asig_sanatate_din_cas else 0 end)),
	sum(a.Somaj_1),sum(a.Asig_sanatate_din_impozit),sum(a.Asig_sanatate_din_net),
	0,sum(a.VENIT_NET),sum(e.avans),sum(case when @Dafora=1 then e.Prime_avans_dafora else e.Premiu_av end),
	sum(a.Debite_externe),sum(a.Rate),sum(a.Debite_interne-(case when @Dafora=1 then e.Prime_avans_dafora+e.Avans_CO_dafora else 0 end)),sum(a.Cont_curent),sum(a.REST_DE_PLATA),
	sum(a.CAS+isnull(d.CAS,0)), sum(a.Somaj_5),sum(a.Fond_de_risc_1),sum(a.Camera_de_Munca_1),sum(a.Asig_sanatate_pl_unitate),sum(a.Ded_suplim),sum(a.VEN_NET_IN_IMP),sum(a.Ded_baza),
	sum(isnull(d.ded_baza,0)),sum(a.VENIT_BAZA),sum((case when i.tip_impozitare='3' or (i.grad_invalid='1' or i.grad_invalid='2') then a.VENIT_BAZA else 0 end)),
	sum(a.Baza_CAS), sum(a.Baza_CAS_cond_norm+isnull(d.Baza_CAS_cond_norm,0)),sum(a.Baza_CAS_cond_deoseb+isnull(d.Baza_CAS_cond_deoseb,0)),
	sum(a.Baza_CAS_cond_spec+isnull(d.Baza_CAS_cond_spec,0)),sum((case when (p.coef_invalid=2 or p.coef_invalid=3 or p.coef_invalid=4) then a.chelt_prof else 0 end)),
	sum((case when p.coef_invalid=1 or p.coef_invalid=9 then a.chelt_prof else 0 end)),sum((case when p.coef_invalid=7 then a.chelt_prof else 0 end)),
	sum((case when p.coef_invalid=8 then a.chelt_prof else 0 end)),
	sum((case when a.somaj_5<>0 and not(@Buget=1 and convert(char(1),actionar)='1') then a.asig_sanatate_din_cas else 0 end)),
	sum((case when a.somaj_5<>0 and @Buget=1 and convert(char(1),actionar)='1' then a.asig_sanatate_din_cas else 0 end)),
	sum((case when a.asig_sanatate_pl_unitate<>0 then b.venit_total-1*(b.Ind_c_medical_CAS+b.CMCAS+b.CMFAMBP)-@CMunitCASS*(b.Ind_c_medical_unitate+b.cmunitate)
		-@NuCASS_H*b.suma_impozabila-(case when dbo.iauParLL(a.data,'PS','STOUG28')=1 then b.Ind_intrerupere_tehnologica_2 else 0 end) else 0 end)),
	sum((case when a.ded_suplim<>0 then d.Baza_CAS else 0 end))*@coefCCI,
	sum((case when a.Camera_de_munca_1<>0 then b.venit_total-1*(b.Ind_c_medical_CAS+b.CMCAS+b.CMFAMBP)-@CMunitITM*(b.Ind_c_medical_unitate+b.cmunitate)
		-@NuCAS_H*b.suma_impozabila-@Cassimps_K*b.cons_admin else 0 end)),
	sum((case when p.coef_invalid=5 then a.venit_total-(b.Ind_c_medical_CAS+b.CMCAS+b.CMFAMBP) else 0 end)),
	sum(isnull(d.ded_suplim,0)),sum(isnull(d.Baza_CAS_cond_norm,0)),sum(isnull(d.Baza_CAS_cond_deoseb,0)),
	sum(isnull(d.Baza_CAS_cond_spec,0)),sum(isnull(d.CAS,0)), sum((case when d.somaj_5<>0 then (case when YEAR(a.Data)<=2011 then isnull(a.asig_sanatate_din_cas,0) 
		when d.CM_incasat<>0 then d.CM_incasat else a.VENIT_TOTAL-(b.Ind_c_medical_CAS+b.CMCAS+b.CMFAMBP) end) else 0 end)),
	sum(isnull(d.somaj_5,0)),sum(isnull(d.asig_sanatate_din_cas,0)),sum((case when i.grupa_de_munca='O' then a.venit_total else 0 end)),
	sum((case when i.grupa_de_munca='P' then a.venit_total else 0 end)), sum(Ore_ingr_copil),
	sum(isnull(e.Nr_tichete,0))-sum(isnull(e.NrTichSupl,0)), sum(isnull(e.Val_tichete,0))-sum(isnull(e.ValTichSupl,0)),sum(isnull(e.NrTichSupl,0)),sum(isnull(e.ValTichSupl,0)), 
	sum(isnull(e.Nr_tichete_acordate,0)),sum(isnull(e.Val_tichete_acordate,0)), 
	sum(e.Ajutor_ridicat_dafora),sum(e.Ajutor_cuvenit_dafora),sum(e.Prime_avans_dafora),sum(e.Avans_CO_dafora),
	sum(e.SPNedet-(case when e.SPNedet=1 then e.Ingrij_copil else 0 end)),sum(e.SPDet-(case when e.SPDet=1 then e.Ingrij_copil else 0 end)),sum(e.Ocazional),sum(e.Ocaz_P),sum(e.Ocaz_P_AS2),
	sum(e.Cm_t_part),sum(e.Handicap),sum(e.Angajat),sum(e.Plecat),sum(e.Plecat_01),sum(e.Ingrij_copil+e.Ocazional),0 as Zilier,
	sum(e.Scut_80),sum(e.Scut_85),max(e.Cotiz_hand),max(d.Asig_sanatate_din_impozit),max(e.Nrms_cnph),
	sum(a.Pensie_suplimentara_3)+sum(a.Somaj_1)+sum(a.Diferenta_impozit+(case when upper(isnull(ii.impozitIpotetic,''))='DA' then 0 else a.Impozit end))+sum(a.Asig_sanatate_din_net)+
		sum(a.Asig_sanatate_pl_unitate)+sum(isnull(d.somaj_5,0))+sum(a.Camera_de_Munca_1) as Virament_partial,
	sum(a.CAS+isnull(d.CAS,0)-(case when @ajdecunit=1 then 0 else isnull(b.Aj_deces,0) end)) as cas_de_virat,
	sum(a.Fond_de_risc_1)-sum(b.CMFAMBP)-sum(a.Asig_sanatate_din_impozit)-sum(isnull(d.ded_suplim,0)), isnull(sum(s.indemnizatie_unitate),0), 
	0 as VenitZilieri, 0 as ImpozitZilieri, 0 as RestPlataZilieri
	from net a 
		left outer join dbo.fluturas_centralizat_brut(@dataJos,@dataSus,@MarcaJ,@MarcaS,@LocmJ,@LocmS,@lGrupaM,@cGrupaM, @lTipSalarizare,@cTipSalJos,@cTipSalSus,@lTipPers,@cTipPers,
			@lFunctie,@cFunctie,@lMandatar,@cMandatar,@lCard,@cCard, @lUnSex,@Sex,@lTipStat,@cTipStat,@AreDreptCond,@cListaCond,@lTipAngajare,@cTipAngajare,@lSirMarci,@cSirMarci, 
			@LmExcep,@StrictLmExcep,@lGrupaMExcep,@exclLM,@setlm,@activitate) b on b.data=a.data and b.marca=a.marca 
		left outer join net d on d.marca=a.marca and d.data=dbo.bom(a.data)
		left outer join personal p on p.marca=a.marca  
		left outer join infopers c on c.marca=a.marca 
		left outer join @fluturas_centralizat_net1 e on e.data=a.data and e.marca=a.marca	-->> functia comentata e folosita in alte locuri!!
/*		dbo.fluturas_centralizat_net1(@dataJos,@dataSus,@MarcaJ,@MarcaS,@LocmJ,@LocmS,@lGrupaM,@cGrupaM, @lTipSalarizare,@cTipSalJos,@cTipSalSus,@lTipPers,@cTipPers,
			@lFunctie,@cFunctie,@lMandatar,@cMandatar,@lCard,@cCard, @lUnSex,@Sex,@lTipStat,@cTipStat,@AreDreptCond,@cListaCond,@lTipAngajare,@cTipAngajare,@lSirMarci,@cSirMarci, 
			@LmExcep,@StrictLmExcep,@lGrupaMExcep,@Grupare)*/
		inner join istpers i on i.data=a.data and i.marca=a.marca  
		left outer join mandatar m on m.loc_munca=a.loc_de_munca 
		left outer join (select Data, Marca, Sum(Indemnizatie_unitate) as Indemnizatie_unitate from dbo.concedii_medicale(@MarcaJ,@MarcaS,@dataJos,@dataSus,'  ','9-',0,'0-',
			@LocmJ,@LocmS,0,0,'1',0,0,'',1,6) Group by Data, Marca) s on s.Data=a.Data and s.Marca=a.Marca 
		left outer join @impozitIpotetic ii on ii.Marca=a.Marca
	where a.data between @dataJos and @dataSus and a.data=dbo.eom(a.data)
		and (@MarcaJ='' or a.marca between @MarcaJ and @MarcaS) 
		and (@LocmJ='' or a.loc_de_munca between @LocmJ and @LocmS) 
		and (@lGrupaM=0 or (@lGrupaMExcep=0 and i.grupa_de_munca=@cGrupaM or @lGrupaMExcep=1 and i.grupa_de_munca<>@cGrupaM)) 
		and (@lTipSalarizare=0 or i.tip_salarizare between @cTipSalJos and @cTipSalSus) 
		and (@lTipPers=0 or @cTipPers='N' and c.Actionar=1 or @cTipPers='C' and c.Actionar=0) and (@lFunctie=0 or i.cod_functie=@cFunctie) 
		and (@lMandatar=0 or m.mandatar=@cMandatar) and (@lCard=0 or p.banca=@cCard) and (@lUnSex=0 or p.sex=@Sex) 
		and (@lTipStat=0 or c.religia=@cTipStat) and (@lDreptCond=0 or (@AreDreptCond=1 and (@cListaCond='T' or @cListaCond='C' and p.pensie_suplimentara=1 
			or @cListaCond='S' and p.pensie_suplimentara<>1)) or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@lTipAngajare=0 or @cTipAngajare='P' and i.grupa_de_munca in ('N','D','S') or @cTipAngajare='O' and i.grupa_de_munca in ('O','C')) 
		and (@lSirMarci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@cSirMarci)>0) 
		and (@LmExcep='' or a.loc_de_munca not like rtrim(@LmExcep)+(case when @StrictLmExcep=1 then '' else '%' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=a.Loc_de_munca))
		and (@exclLM is null or not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='NUSTAT' and valoare=@exclLM and a.loc_de_munca=p.Cod))
		and (@setlm is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(a.Loc_de_munca) like rtrim(p.cod)+'%'))
		and (@activitate is null or p.Activitate=@activitate)
	group by a.Data,a.Marca
--	adaug si personele din istpers plecate cu data de 01 a lunii si care nu au pozitie in net 
--	pentru contorizare salariati plecati si corelatie in nr. salariati la finalul lunii si nr. salariati la inceputul lunii urmatoare
	union all
	select i.Data, i.Marca,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 as Plecat_01,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0
	from istPers i 
		left outer join personal p on i.Marca=p.Marca  
		left outer join infopers c on c.Marca=i.Marca 
	where i.Data between @dataJos and @dataSus and p.Loc_ramas_vacant=1 and p.Data_plec=dbo.bom(i.Data)
		and (@MarcaJ='' or i.Marca between @MarcaJ and @MarcaS) 
		and (@LocmJ='' or i.Loc_de_munca between @LocmJ and @LocmS) 
		and (@lFunctie=0 or i.Cod_functie=@cFunctie) 
		and (@lCard=0 or p.Banca=@cCard) and (@lUnSex=0 or p.Sex=@Sex) 
		and (@lSirMarci=0 or charindex(','+rtrim(ltrim(i.Marca))+',',@cSirMarci)>0) and (@lTipStat=0 or c.religia=@cTipStat) 
		and (@LmExcep='' or i.Loc_de_munca not like rtrim(@LmExcep)+(case when @StrictLmExcep=1 then '' else '%' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.Loc_de_munca))
		and (@exclLM is null or not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='NUSTAT' and valoare=@exclLM and i.Loc_de_munca=p.Cod))
		and not exists (select marca from net n where n.Data=i.Data and n.Marca=i.Marca)
		and (@setlm is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(i.Loc_de_munca) like rtrim(p.cod)+'%'))
		and (@activitate is null or p.Activitate=@activitate)
	group by i.Data, i.Marca
--	adaug si veniturile/impozitul zilierilor
	union all
	select dbo.eom(s.Data), s.marca,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 as Zilier,0,0,0,0,0,
	sum(Impozit) as Virament_partial,0,0,0,sum(Venit_total) as VenitZilieri, sum(Impozit) as ImpozitZilieri, sum(Rest_de_plata) as RestPlataZilieri
	from SalariiZilieri s 
		left outer join Zilieri z on z.marca=s.marca  
		left outer join infopers c on c.marca=s.marca 
		left outer join mandatar m on m.loc_munca=s.Loc_de_munca 
	where s.data between @dataJos and @dataSus 
		and (@MarcaJ='' or s.marca between @MarcaJ and @MarcaS) 
		and (@LocmJ='' or s.loc_de_munca between @LocmJ and @LocmS) 
		and (@lFunctie=0 or z.Cod_functie=@cFunctie) 
		and (@lMandatar=0 or m.mandatar=@cMandatar) and (@lCard=0 or z.Banca=@cCard) and (@lUnSex=0 or z.Sex=@Sex) 
		and (@lSirMarci=0 or charindex(','+rtrim(ltrim(z.Marca))+',',@cSirMarci)>0) 
		and (@LmExcep='' or z.Loc_de_munca not like rtrim(@LmExcep)+(case when @StrictLmExcep=1 then '' else '%' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=z.Loc_de_munca))
		and (@exclLM is null or not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='NUSTAT' and valoare=@exclLM and z.Loc_de_munca=p.Cod))
		and (@setlm is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(z.Loc_de_munca) like rtrim(p.cod)+'%'))
		and @lTipStat=0	-- tratat ca daca se face filtru dupa tip stat plata sa nu aduca sumele zilierilor (acestia nu au informatia privind tipul de stat de plata).
	group by dbo.eom(s.Data), s.Marca
	return
end
