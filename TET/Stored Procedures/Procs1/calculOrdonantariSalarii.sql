--***
/**	procedura pentru calcul ordonantari salarii (contributii indviduale, unitate, rest de plata repartizat pe indicatori bugetari conform setarilor din nota contabila)	*/
Create procedure calculOrdonantariSalarii
	@dataJos datetime, @dataSus datetime, @locm varchar(9)=null, @marca varchar(6)=null, 
	@tipCalcul int=1,	--	1 = contributii pe coduri bugetare
						--	2 = rest de plata pe coduri bugetare si banci
						--	3 = nota contabila contributii angajati
						--	4 = nota contabila retineri salarii din net
	@locmExceptie varchar(200)=null, 
	@fltLocmChelt int=0	--	repartizare contributii angajat pe loc de munca de cheltuiala.
As
Begin try
	if exists (select * from sysobjects where name ='calculOrdonantariSalariiSP')
		exec calculOrdonantariSalariiSP @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marca, @locm=@locm, @tipCalcul=@tipCalcul

	declare @utilizator varchar(20), @lista_lm int, @IndCondSalBaza int, @SpSpecSalBaza int, @Sp1SalBaza int, @ProcentImpozit decimal(10,2), @AjDecesUnitate int, 
		@CreditCMCas1 varchar(20), @DebitCMCas2 varchar(20), @CreditCMCas2 varchar(20)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	select	@SpSpecSalBaza=max(case when parametru='S-BAZA-SP' then val_logica else @SpSpecSalBaza end), 
			@IndCondSalBaza=max(case when parametru='SBAZA-IND' then val_logica else @IndCondSalBaza end),
			@Sp1SalBaza=max(case when parametru='S-BAZA-S1' then val_logica else @Sp1SalBaza end),
			@AjDecesUnitate=max(case when parametru='AJDUNIT-R' then val_logica else @AjDecesUnitate end)
	from par 
	where tip_parametru='PS' and parametru in ('S-BAZA-SP','SBAZA-IND','S-BAZA-S1','AJDUNIT-R')

	set @CreditCMCas1=dbo.iauParA('PS','N-C-CMC1C')
	set @DebitCMCas2=dbo.iauParA('PS','N-C-CMC2D')
	set @CreditCMCas2=dbo.iauParA('PS','N-C-CMC2C')

	select @ProcentImpozit=max(procent)
	from impozit
	where Tip_impozit='P'

	if @marca is null set @marca=''
	if @locm is null set @locm=''
	if @locmExceptie is null set @locmExceptie=''

	if object_id('tempdb..#istpers') is not null drop table #istpers
	if object_id('tempdb..#resal') is not null drop table #resal
	if object_id('tempdb..#sbrut') is not null drop table #sbrut
	if object_id('tempdb..#tmpbrut') is not null drop table #tmpbrut
	if object_id('tempdb..#cnet') is not null drop table #cnet
	if object_id('tempdb..#sume') is not null drop table #sume
	if object_id('tempdb..#sumeDet') is not null drop table #sumedet
	if object_id('tempdb..#brutmarca') is not null drop table #brutmarca
	if object_id('tempdb..#par_lunari') is not null drop table #par_lunari
	if object_id('tempdb..#conturi') is not null drop table #conturi
	if object_id('tempdb..#contributii') is not null drop table #contributii
	if object_id('tempdb..#retineri') is not null drop table #retineri
	if object_id('tempdb..#tmpsalarnet') is not null drop table #tmpsalarnet
	if object_id('tempdb..#salarnet') is not null drop table #salarnet
	if object_id('tempdb..#restplata') is not null drop table #restplata
	if object_id('tempdb..#confignc') is not null drop table #confignc
	if object_id('tempdb..#retineriNerep') is not null drop table #retineriNerep

	CREATE TABLE dbo.#sumeDet
		(Data datetime, TipSuma varchar(30), Marca varchar(6), lm varchar(9), Suma float, Indicator varchar(20), Explicatii varchar(1000), Numar varchar(10), idpoz int identity) 

	CREATE TABLE dbo.#sume
		(Data datetime, TipSuma varchar(30), Suma float, Indicator varchar(20), ExplicatiiSuma varchar(1000), TipContributii varchar(30), ExplicatiiContributii varchar(1000), idpoz int identity) 

	CREATE TABLE dbo.#contributii
		(Data datetime, TipSuma varchar(30), Marca varchar(6), lm varchar(9), Suma float, Indicator varchar(20), ExplicatiiSuma varchar(1000), 
		TipContributii varchar(30), ExplicatiiContributii varchar(1000), idpoz int identity) 
	
	/* selectare date in tabele temporare din tabelele de baza */
	select * into #par_lunari 
	from par_lunari
	where data between @datajos and @dataSus and tip='PS'

	select c.cont, c.detalii.value('(/row/@indicator)[1]','varchar(20)') as indicator
	into #conturi
	from conturi c

	select i.* into #istpers
	from istpers i
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where i.data between @dataJos and @dataSus
		and (@lista_lm=0 or lu.cod is not null)
		and (@marca='' or i.marca=@marca)
		and (@locm='' or @fltLocmChelt=1 or @fltLocmChelt=0 and i.loc_de_munca like rtrim(@locm)+'%')

	select r.* into #resal
	from resal r
		left outer join #istpers i on i.Data=r.Data and i.Marca=r.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where r.data between @dataJos and @dataSus
		and (@lista_lm=0 or lu.cod is not null)
		and (@marca='' or r.marca=@marca)
		and (@locm='' or @fltLocmChelt=1 or @fltLocmChelt=0 and i.loc_de_munca like rtrim(@locm)+'%')

	select b.* into #tmpbrut 
	from brut b
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=b.loc_de_munca
	where b.data between @dataJos and @dataSus 
		and (@lista_lm=0 or lu.cod is not null)
		and (@marca='' or b.marca=@marca)

	select n.data, n.marca, (case when @fltLocmChelt=1 and @locm<>'' then @locm else n.Loc_de_munca end) as lm, i.Grupa_de_munca, n.CO_incasat, n.VENIT_TOTAL, 
		n.Suma_neimpozabila, n.Pensie_suplimentara_3 as CASAngajat, n.Somaj_1 as SomajAngajat, n.Asig_sanatate_din_net as CassAngajat, n.Impozit+n.Diferenta_impozit as Impozit, 
		n.cas+isnull(n1.cas,0) as CasAngajator, n.asig_sanatate_pl_unitate as CassAngajator, n.somaj_5 as SomajAngajator, n.Fond_de_risc_1 as Faambp, n.Ded_suplim as CCI, isnull(n1.Somaj_5,0) as FondGarantare, 
		isnull(n1.Baza_CAS_cond_norm+n1.Baza_CAS_cond_deoseb+n1.Baza_CAS_cond_spec,0) as BazaCASCM, 
		n.Avans+n.Premiu_la_avans as avans, n.Suma_incasata, n.Debite_externe, n.Debite_interne, n.Rate, n.Cont_curent, n.Rest_de_plata, 
		isnull(n1.Ded_suplim,0) as CCIDinFaambp, n.Asig_sanatate_din_impozit as CassDinFaambp, isnull(n1.Asig_sanatate_din_impozit,0) as CassPtFaambp, 
		n.Chelt_prof as SubventieSomaj, isnull(ss.Scutire_art80+ss.Scutire_art85,0) as ScutireSomaj, convert(decimal(17,8),0) as procent
	into #cnet 
	from net n
		left outer join net n1 on n1.data=dbo.BOM(n.data) and n1.marca=n.marca
		left outer join personal p on p.marca=n.marca
		left outer join #istpers i on i.data=n.data and i.marca=n.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=n.loc_de_munca
		left outer join dbo.fScutiriSomaj (@dataJos , @dataSus, '', 'ZZZ', '', 'ZZZ') ss on ss.Data=n.Data and ss.Marca=n.Marca
	where n.data between @dataJos and @dataSus and n.Data=dbo.EOM(n.data)
		and n.Data>=p.Data_angajarii_in_unitate
		and (@lista_lm=0 or lu.cod is not null)
		and (@marca='' or n.marca=@marca)
		and (@locm='' or @fltLocmChelt=1 or @fltLocmChelt=0 and n.loc_de_munca like rtrim(@locm)+'%')

	select b.Data, b.Marca, (case when @tipCalcul=3 or @fltLocmChelt=1 then b.Loc_de_munca else n.lm end) as lm, max(n.Grupa_de_munca) as Grupa_de_munca, sum(b.Venit_total) as Venit_total, 
		sum(b.Realizat__regie+b.Realizat_acord+b.Ind_intrerupere_tehnologica+b.Ind_invoiri+b.Salar_categoria_lucrarii-
		(case when @IndCondSalBaza=1 then round(b.Ind_nemotivate,0) else 0 end)-(case when @SpSpecSalBaza=1 then round(b.Spor_specific,0) else 0 end)-
		(case when @Sp1SalBaza=1 then round(b.Spor_cond_1,0) else 0 end)) as SalarDeBaza, 
		sum(b.Indemnizatie_ore_supl_1+b.Indemnizatie_ore_supl_2+b.Indemnizatie_ore_supl_3+b.Indemnizatie_ore_supl_4+ b.Indemnizatie_ore_spor_100) as IndOreSuplim, 
		sum(b.Ind_obligatii_cetatenesti+b.Ind_concediu_de_odihna) as IndCO, sum(b.Ind_c_medical_unitate+b.CMunitate) as IndCMUnitate, sum(b.Ind_c_medical_CAS+b.CMCAS) as IndCMFnuass, 
		sum(b.CO-isnull(cz.suma_corectie,0)) as CorD, sum(isnull(cz.suma_corectie,0)) as CorZ, sum(b.Restituiri) as Restituiri, sum(-b.Diminuari) as Diminuari, 
		sum(b.Suma_impozabila) as SumaImpozabila, sum(b.Premiu-isnull(cx.suma_corectie,0)) as Premiu, sum(isnull(cx.suma_corectie,0)) as Premiu2, 
		sum(b.Diurna-isnull(cy.suma_corectie,0)) as Diurna, sum(isnull(cy.suma_corectie,0)) as Diurna2, sum(b.Cons_admin) as ConsAdmin, sum(b.Sp_salar_realizat) as CorL, 
		sum(b.Suma_imp_separat) as CorO, 
		sum(case when @IndCondSalBaza=1 or 1=1 then round(b.Ind_nemotivate,0) else 0 end) as IndCond, 
		sum(case when @SpSpecSalBaza=1 or 1=1 then round(b.Spor_specific,0) else 0 end) as SporSpecific, 
		sum(b.Spor_vechime) as SporVechime, sum(b.Ind_ore_de_noapte+b.Spor_de_noapte) as SporDeNoapte, sum(b.Spor_sistematic_peste_program) as SporSistProgram, 
		sum(b.Spor_de_functie_suplimentara) as SporFctSuplim, 
		sum(case when @Sp1SalBaza=1 or 1=1 then round(b.Spor_cond_1,0) else 0 end) as SporCond1, sum(round(b.Spor_cond_2,0)) as SporCond2, sum(round(b.Spor_cond_3,0)) as SporCond3, 
		sum(round(b.Spor_cond_4,0)) as SporCond4, sum(round(b.Spor_cond_5,0)) as SporCond5, sum(round(b.Spor_cond_6,0)) as SporCond6, sum(round(b.Spor_cond_7,0)) as SporCond7,
		(case when @AjDecesUnitate=0 then sum(b.Compensatie) else 0 end) as AjutorDeces, sum(isnull(q.Suma_corectie,0)) as AjutoareMateriale, 
		sum(b.Spor_cond_9) as IndCMFaambp, sum(n.Suma_neimpozabila) as SumaNeimpozabila, isnull(max(cm.CMScutitImpozit),0) as CMScutitImpozit, 
		isnull(max(n.BazaCASCM),0) as BazaCASCM, isnull(round(max(case when cm.ZileCM=0 then 0 else n.BazaCASCM*cm.ZileCMUnitate/cm.ZileCM end),0),0) as BazaCASCMUnitate, 
		isnull(round(max(case when cm.ZileCM=0 then 0 else n.BazaCASCM*cm.ZileCMFnuass/cm.ZileCM end),0),0) as BazaCASCMFnuass
	into #sbrut 
	from #tmpbrut b
		left outer join #cnet n on n.data=b.data and n.marca=b.marca
		left outer join #istpers i on i.data=b.data and i.marca=b.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'X-', '', '', 1) cx on cx.data=b.data and cx.marca=b.marca and cx.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Y-', '', '', 1) cy on cy.data=b.data and cy.marca=b.marca and cy.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Z-', '', '', 1) cz on cz.data=b.data and cz.marca=b.marca and cz.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', '', '', 1) q on q.Data=b.Data and q.Marca=b.Marca and q.Loc_de_munca=b.Loc_de_munca 
		left outer join (select data, marca, sum(Zile_cu_reducere) as ZileCMUnitate, sum(Zile_lucratoare-Zile_cu_reducere) as ZileCMFnuass, sum(Zile_lucratoare) as ZileCM, 
			sum(case when tip_diagnostic in ('8-','9-','15') then indemnizatie_cas else 0 end) as CMScutitImpozit 
			from conmed where data between @datajos and @datasus and tip_diagnostic not in ('0-','2-','3-','4-')
			group by data, marca) cm on cm.data=b.data and cm.marca=b.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=b.loc_de_munca
	where (@locm='' or @fltLocmChelt=0 and i.loc_de_munca like rtrim(@locm)+'%' or @fltLocmChelt=1 and b.loc_de_munca like rtrim(@locm)+'%')
		and (@locmExceptie='' or CHARINDEX(RTRIM(b.Loc_de_munca)+',',@locmExceptie)=0)
	group by b.data, b.marca, (case when @tipCalcul=3 or @fltLocmChelt=1 then b.Loc_de_munca else n.lm end)

	select distinct a.lm, c.Numar_pozitie, c.Identificator, c.Cont_debitor, c.Cont_creditor, c.denumire, c.Comanda, c.Cont_CAS, c.Cont_CASS, c.Cont_somaj, c.Cont_impozit
	into #confignc
	from #sbrut a
		outer apply (select * from config_nc c where (a.lm like RTRIM(c.Loc_de_munca)+'%' 
			or c.Loc_de_munca is null and not exists (select 1 from config_nc c1 where a.lm like RTRIM(c1.Loc_de_munca)+'%'))) c

	if @fltLocmChelt=1
	begin
		update n set procent=(case when b.venit_total>0 then n.venit_total/b.venit_total else 1 end)
		from #cnet n
			left outer join #tmpbrut b on b.data=n.data and b.marca=n.marca and (@locm<>'' and @locmExceptie='' and b.Loc_de_munca=@locm or @locmExceptie<>'' and CHARINDEX(RTRIM(b.Loc_de_munca)+',',@locmExceptie)=0)
		
		--sterg marcile care nu tin de filtrarea locului de munca de cheltuiala
		if @locm<>'' and @locmExceptie=''
			delete n from #cnet n where not exists (select 1 from #tmpbrut b where b.data=n.data and b.marca=n.marca 
				and (b.Loc_de_munca=@locm /*or @locmExceptie<>'' and CHARINDEX(RTRIM(b.Loc_de_munca)+',',@locmExceptie)=0*/))

		update #cnet set CasAngajat=round(CasAngajat/Procent,2), CassAngajat=round(CassAngajat/Procent,2), SomajAngajat=round(SomajAngajat/Procent,2), Impozit=round(Impozit/Procent,2),
			CasAngajator=round(CasAngajator/Procent,2), CassAngajator=round(CassAngajator/Procent,2), SomajAngajator=round(SomajAngajator/Procent,2), 
			Faambp=round(Faambp/Procent,2), FondGarantare=round(FondGarantare/Procent,2), CCI=round(CCI/Procent,2)
		--select * from #cnet
	end

	/* sume brute pe indicatori bugetari */
	/* salarii de baza - permanenti */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SALARBAZA', b.Marca, b.lm, b.SalarDeBaza as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=1 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor
	where b.Grupa_de_munca not in ('O','P')

	/* salarii de baza - ocazionali neplatitori CAS*/
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SALARBAZA_O', b.Marca, b.lm, b.SalarDeBaza as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, 
		rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=2 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor
	where b.Grupa_de_munca in ('O')

	/* salarii de baza - ocazionali platitori CAS*/
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SALARBAZA_P', b.Marca, b.lm, (b.SalarDeBaza) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=4 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor
	where b.Grupa_de_munca in ('p')

	/* concedii medicale suportate de unitate */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CMUNITATE', b.Marca, b.lm, (b.IndCMUnitate) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=3 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Indemnizatie de concediu de odihna */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CONCODIH', b.Marca, b.lm, (b.IndCO) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=20 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* indemnizatii pentru ore suplimentare */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'ORESUPLIMENTARE', b.Marca, b.lm, (b.IndOreSuplim) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=5 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* indemnizatie pentru ore suplimentare */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORNOAPTE', b.Marca, b.lm, (b.SporDeNoapte) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=6 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* indemnizatie de conducere */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'INDCONDUCERE', b.Marca, b.lm, (b.IndCond) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=7 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor specific */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORSPECIFIC', b.Marca, b.lm, (b.SporSpecific) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=8 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor specific */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORSISTPPRG', b.Marca, b.lm, (b.SporSistProgram) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=9 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor vechime */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORVECHIME', b.Marca, b.lm, (b.SporVechime) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=10 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor de functie suplimentara */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORFCTSUPL', b.Marca, b.lm, (b.SporFctSuplim) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=11 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 1 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND1', b.Marca, b.lm, (b.SporCond1) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=12 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 2 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND2', b.Marca, b.lm, (b.SporCond2) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=13 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 3 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND3', b.Marca, b.lm, (b.SporCond3) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=14 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 4 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND4', b.Marca, b.lm, (b.SporCond4) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=16 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 5 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND5', b.Marca, b.lm, (b.SporCond5) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=17 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 6 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND6', b.Marca, b.lm, (b.SporCond6) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=18 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Spor conditii 7 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'SPORCOND7', b.Marca, b.lm, (b.SporCond7) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=19 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Indemnizatie de concediu medical suportata din FNUASS */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CMFNUASS', b.Marca, b.lm, (b.IndCMFnuass) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=22 and cn.lm=b.lm
		left outer join #conturi c on c.cont=(case when cn.Cont_creditor=@DebitCMCas2 then @CreditCMCas2 else @CreditCMCas1 end)

	/* Indemnizatie de concediu medical suportata din FAAMBP */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CMFAAMBP', b.Marca, b.lm, (b.IndCMFaambp) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=23 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia D */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-D', b.Marca, b.lm, (b.CorD) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=25 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia Z */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-Z', b.Marca, b.lm, (b.CorZ) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=27 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia F-Restituiri */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-F', b.Marca, b.lm, (b.Restituiri) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=30 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia G-Diminuari */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-G', b.Marca, b.lm, (b.Diminuari) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=32 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia H-Suma impozabila */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-H', b.Marca, b.lm, (b.SumaImpozabila) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=35 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia I-Premiu */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-I', b.Marca, b.lm, (b.Premiu) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=40 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia X-Premiu2 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-X', b.Marca, b.lm, (b.Premiu2) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=42 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia J-Diurna */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-J', b.Marca, b.lm, (b.Diurna) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=45 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia Y-Diurna2 */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-Y', b.Marca, b.lm, (b.Diurna2) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=47 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia K-Cons admin */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-K', b.Marca, b.lm, (b.ConsAdmin) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=50 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia L-Procent lucrat acord */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-L', b.Marca, b.lm, (b.CorL) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=51 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia O-Suma impozitata separat */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-O', b.Marca, b.lm, (b.CorO) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=60 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia R-Ajutor deces */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-R', b.Marca, b.lm, (b.AjutorDeces) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=65 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Sume inregistrate pe corectia Q-Ajutoare materiale */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select b.Data, 'CORECTIA-Q', b.Marca, b.lm, (b.AjutoareMateriale) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from #sbrut b
		left outer join #confignc cn on cn.Numar_pozitie=67 and cn.lm=b.lm
		left outer join #conturi c on c.cont=cn.Cont_debitor

	/* Tichete de masa */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select t.data, 'Data', t.Marca, t.Loc_de_munca, (t.Valoare_tichete) as suma, isnull(nullif(c.indicator,''),cn.Comanda) as indicator, rtrim(cn.Denumire) as explicatii
	from fNC_tichete (@dataJos, @dataSus, @Marca, 1) t
		left outer join #confignc cn on cn.Numar_pozitie=70 and cn.lm=t.loc_de_munca
		left outer join #conturi c on c.cont=cn.Cont_debitor

	alter table #sumeDet add tipDate varchar(20)
	update #sumeDet set tipDate='BRUT'

	/* contributii angajat */
	/* asigurari sociale - permanenti */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select n.Data, 'CASANGAJAT', n.Marca, n.lm, n.CasAngajat as suma, '' as indicator, 
		'Asigurari CAS individual '+convert(varchar(10),convert(decimal(12,2),pl.Val_numerica))+'%' as explicatii
	from #cnet n
		left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASINDIV'

	/* asigurari sociale - ocazionali */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select n.Data, 'CASSANGAJAT', n.Marca, n.lm, n.CassAngajat as suma, '' as indicator, 
		'Asigurari sanatate din net '+convert(varchar(15),convert(decimal(12,2),pl.Val_numerica))+'%' as explicatii
	from #cnet n
		left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASSIND'

	/* asigurari sociale de somaj - permanenti */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select n.Data, 'SOMAJANGAJAT', n.Marca, n.lm, n.SomajAngajat as suma, '' as indicator, 
		'Somaj '+convert(varchar(10),convert(decimal(12,2),pl.Val_numerica))+'%' as explicatii
	from #cnet n
		left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='SOMAJIND'

	/* Impozit */
	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii)	
	select n.Data, 'IMPOZIT', n.Marca, n.lm, n.Impozit as suma, '' as indicator, 
		'Impozit '+convert(varchar(10),@ProcentImpozit)+'%' as explicatii
	from #cnet n

	/* de aici incepe repartizarea contributiilor angajat pe indicatori bugetari aferent cheltuielilor salariale */
	update #sumeDet set tipDate='ASIGANGAJAT'
	where tipDate is null

	insert into #sumeDet (Data, TipSuma, Marca, lm, Suma, Indicator, Explicatii, Numar)
	select r.Data, r.Cod_beneficiar, r.Marca, '', r.Retinut_la_lichidare as suma, isnull(nullif(cc.indicator,''),isnull(cd.indicator,'')) as indicator, 
		b.Denumire_beneficiar as explicatii, Numar_document
	from #resal r
		left outer join benret b on b.Cod_beneficiar=r.Cod_beneficiar
		left outer join #conturi cc on cc.Cont=b.Cont_creditor
		left outer join #conturi cd on cd.Cont=b.Cont_debitor
	union all 
	select n.Data, 'AVANSSALAR', n.Marca, n.lm, n.avans as suma, '' as indicator, 
		'Avans angajati' as explicatii, ''
	from #cnet n
	union all 
	select n.Data, 'CORECTIA-M', n.Marca, n.lm, n.Suma_incasata as suma, '' as indicator, 
		'Suma incasata' as explicatii, ''
	from #cnet n
	union all 
	select n.Data, 'CORECTIA-E', n.Marca, n.lm, n.CO_incasat as suma, '' as indicator, 
		'CO incasat' as explicatii, ''
	from #cnet n

	update #sumeDet set tipDate='RETINERI'
	where tipDate is null

	/*stergere pozitii nule */
	delete from #sumeDet where convert(decimal(12,2),isnull(suma,0))=0

	select Data, Marca, sum(Suma) as suma
	into #brutmarca
	from #sumeDet
	where tipDate='BRUT' and TipSuma not in ('CORECTIA-R')
	group by data, marca

	if exists (select * from sysobjects where name ='calculOrdonantariSalariiSP1')
		exec calculOrdonantariSalariiSP1 @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marca, @locm=@locm, @tipCalcul=@tipCalcul

	/* repartizare contributii sociale */
	/* pentru contributia de sanatate nu se iau in calcul indemnizatiile de concediu medical */
	/* pentru contributia de somaj nu se iau in calcul indemnizatiile de concediu medical suportate din FNUASS si FAAMBP */
	insert into #contributii (Data, TipSuma, Marca, lm, Suma, Indicator, ExplicatiiSuma, TipContributii, ExplicatiiContributii)
	select br.data, br.TipSuma, c.marca, sb.lm, 
		round(c.Suma*(br.Suma-(case when c.TipSuma in ('CASANGAJAT','CASSANGAJAT') and br.TipSuma='CMUNITATE' then sb.IndCMUnitate
				when c.TipSuma in ('CASANGAJAT','CASSANGAJAT','SOMAJANGAJAT') and br.TipSuma='CMFNUASS' then sb.IndCMFnuass
				when c.TipSuma in ('CASANGAJAT','CASSANGAJAT','SOMAJANGAJAT') and br.TipSuma='CMFAAMBP' then sb.IndCMFaambp 
				else 0 end)+(case when c.TipSuma='CASANGAJAT' and br.TipSuma='CMUNITATE' then sb.BazaCASCMUnitate 
							when c.TipSuma='CASANGAJAT' and br.TipSuma='CMFNUASS' then sb.BazaCASCMFnuass else 0 end))
			/(bm.Suma-(case when c.TipSuma in ('CASANGAJAT','CASSANGAJAT') then sb.IndCMUnitate+sb.IndCMFnuass+sb.IndCMFaambp 
			when c.TipSuma='SOMAJANGAJAT' then sb.IndCMFnuass+sb.IndCMFaambp else 0 end)
				+(case when c.TipSuma='CASANGAJAT' then sb.BazaCASCM else 0 end)),0) as suma, 
		br.Indicator, br.Explicatii, c.TipSuma as TipContributii, 
		rtrim(c.Explicatii)+(case when br.TipSuma in ('CMUNITATE','CMFNUASS','CMFAAMBP') then ' - bolnavi' else ' - activi' end) as ExplContrib
		--, bm.suma, br.suma, sb.IndCMUnitate, sb.IndCMFnuass, sb.IndCMFaambp
	from #sumeDet c
		left outer join #brutmarca bm on bm.data=c.data and bm.marca=c.marca
		left outer join #sumeDet br on br.data=c.data and br.marca=c.marca and br.TipDate='BRUT' and br.TipSuma not in ('TICHETE','CORECTIA-R','CORECTIA-Q')
		left outer join #sbrut sb on sb.data=c.data and sb.marca=c.marca and br.lm=sb.lm
	where c.tipDate='ASIGANGAJAT' and c.TipSuma<>'IMPOZIT'
	order by br.idpoz

	insert into #contributii (Data, TipSuma, Marca, lm, Suma, Indicator, ExplicatiiSuma, TipContributii, ExplicatiiContributii)
	select br.Data, br.TipSuma, c.marca, sb.lm, round(c.Suma*(br.Suma-(case when br.TipSuma='CMFNUASS' then sb.CMScutitImpozit else 0 end))/(bm.Suma-sb.CMScutitImpozit),0) as suma, 
		br.Indicator, br.Explicatii, 
		c.TipSuma as TipContributii, rtrim(c.Explicatii)+(case when br.TipSuma in ('CMUNITATE','CMFNUASS','CMFAAMBP') then ' - bolnavi' else ' - activi' end) as ExplContrib
		--, c.suma, bm.suma, br.suma, sb.CMScutitImpozit
	from #sumeDet c
		left outer join #brutmarca bm on bm.data=c.data and bm.marca=c.marca
		left outer join #sumeDet br on br.data=c.data and br.marca=c.marca and br.TipDate='BRUT' and br.TipSuma not in ('CORECTIA-R','CORECTIA-Q')
		left outer join #sbrut sb on sb.data=c.data and sb.marca=c.marca and br.lm=sb.lm
	where c.tipDate='ASIGANGAJAT' and c.TipSuma='IMPOZIT'
	order by br.idpoz

	/* pun in tabela prima pozitie pentru fiecare marca si contributie pe care fac reglarea diferentelor rezultate din repartizare. Merge mai repede decat cu "idpoz in" */
	select * into #tmpcontributii from 
	(select Data, Marca, TipContributii, idPoz, RANK() over (partition by Data, Marca, TipContributii order by idPoz) as ordine
	from #contributii) a
	where Ordine=1

	update rs set rs.suma=rs.suma+(tot.Suma-rep.Suma)
	from #contributii rs
		left outer join #sumedet tot on tot.data=rs.data and tot.marca=rs.marca and tot.TipSuma=rs.TipContributii
		left outer join (select data, marca, TipContributii, sum(suma) as suma from #contributii group by data, marca, TipContributii) rep
			on rep.data=rs.data and rep.marca=rs.marca and rep.TipContributii=rs.TipContributii
	where exists (select 1 from #tmpcontributii t where t.data=rs.data and t.marca=rs.marca and t.TipContributii=rs.TipContributii and t.idpoz=rs.idpoz)
--	where rs.idpoz in (select top 1 idpoz from #contributii r where r.data=rs.data and r.marca=rs.marca and r.TipContributii=rs.TipContributii order by r.idpoz)
	delete from #contributii where suma=0

	insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma, TipContributii, ExplicatiiContributii)
	select Data, TipSuma, sum(Suma), Indicator, ExplicatiiSuma, TipContributii, ExplicatiiContributii
	from #contributii
	where suma<>0
	group by Data, TipSuma, Indicator, ExplicatiiSuma, TipContributii, ExplicatiiContributii
	order by min(idpoz)
	/* terminat repartizare contributii angajat */

	/* repartizare retineri din salarul net. Se va stabili mai intai salarul net pentru fiecare suma bruta si din acest net se va efectua retinerea TOP-DOWN (in ordinea salar de baza, etc) */
	select Data, TipSuma, Marca, sum(Suma) as suma, Indicator, Explicatii, 'SALARNET' as TipContributii, 'Salar net' as ExplicatiiContributii, min(idpoz) as idpoz
	into #tmpsalarnet
	from #sumeDet
	where tipDate='BRUT' and TipSuma<>'TICHETE' and suma<>0
	group by Data, TipSuma, Marca, Indicator, Explicatii
	union all 
	select Data, TipSuma, Marca, sum(-1*Suma), Indicator, ExplicatiiSuma, 'SALARNET', 'Salar net', min(idpoz) as idpoz
	from #contributii
	where suma<>0
	group by Data, TipSuma, Marca, Indicator, ExplicatiiSuma

	select Data, TipSuma, Marca, sum(Suma) as suma, Indicator, Explicatii, 'SALARNET' as TipContributii, 'Salar net' as ExplicatiiContributii, min(idpoz) as idpoz 
	into #salarnet
	from #tmpsalarnet
	group by Data, TipSuma, Marca, Indicator, Explicatii, TipContributii, ExplicatiiContributii 
	order by min(idpoz)

	--tabela cu retinerile de repartizat 
	select ROW_NUMBER() over (partition by a.Data,a.Marca order by a.Data,a.Marca,a.Indicator,a.idpoz,a.TipSuma) as nrp, 0 as nrmin, 0 as nrmax,
		a.TipSuma, a.Marca, a.Indicator, a.Data, a.Suma, CONVERT(float,0.00) as cumulat, a.Explicatii, a.idpoz, 
		1 as se_repartizeaza, Numar
	into #retineriDeRep
	from #sumeDet a
	where a.tipDate='RETINERI'
	order by a.Data,a.Marca,a.idpoz,a.TipSuma

	select top 0 * into #retineriNerep from #retineriDeRep
	if exists (select * from sysobjects where name ='calculOrdonantariSalariiSPRet1')
		exec calculOrdonantariSalariiSPRet1 @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marca, @locm=@locm, @tipCalcul=@tipCalcul

	--tabela cu componenta brutului pe care se va face repartizare 
	select ROW_NUMBER() over (partition by a.Data, a.Marca order by a.Data,a.Marca,a.idpoz,a.TipSuma) as nrp,
		a.TipSuma, a.Marca, a.Indicator, a.Data, a.Suma, CONVERT(float,0.00) as cumulat, a.Explicatii, a.idpoz
	into #salarNetPtRep
	from #salarnet a
	where a.suma>0
	order by a.Data,a.Marca,a.idpoz,a.TipSuma

	--solduri cumulate pe care se fac repartizarile
	update #salarNetPtRep set 
		cumulat=netcalculat.cumulat
	from (select p2.Data, p2.Marca, p2.nrp, sum(p1.suma) as cumulat 
			from #salarNetPtRep p1, #salarNetPtRep p2 
			where p1.Data=p2.Data and p1.Marca=p2.Marca and p1.nrp<=p2.nrp 
			group by p2.Data, p2.Marca, p2.nrp) netcalculat
	where netcalculat.Marca=#salarNetPtRep.Marca
		and netcalculat.nrp=#salarNetPtRep.nrp
	
	--solduri cumulate pentru retinerile de repartizat
	update #retineriDeRep set 
		cumulat=retinericalculate.cumulat
	from (select p2.Data, p2.Marca, p2.nrp, sum(case when p1.Suma<0 then 0 else p1.Suma end) as cumulat 
		from #retineriDeRep p1, #retineriDeRep p2 
		where p1.Marca=p2.Marca and p1.nrp<=p2.nrp 
		group by p2.Data, p2.Marca, p2.nrp) retinericalculate
	where retinericalculate.Marca=#retineriDeRep.Marca
		and retinericalculate.nrp=#retineriDeRep.nrp  

	--calcul numar min
	update #retineriDeRep 
			set nrmin=(case when Suma<0 then 1 else st.nrp end)--,nrmax=dr.nrp
		from #retineriDeRep c
			cross apply
				(select top 1 smin.nrp from #salarNetPtRep smin where smin.Data=c.Data and smin.Marca=c.Marca and c.cumulat-c.suma<smin.cumulat order by smin.cumulat) st 

	--calcul numar max
	update #retineriDeRep 
			set nrmax=dr.nrp
		from #retineriDeRep c	
			cross apply
				(select Top 1 smax.nrp from #salarNetPtRep smax where smax.Data=c.Data and smax.Marca=c.Marca and (smax.cumulat<=c.cumulat or smax.cumulat-smax.suma<c.cumulat) order by smax.cumulat desc) dr

	--imperechere retineri cu salarul net. In primul select repartizez doar retinerile fara indicator in dreptul contului creditor
	select row_number() over(order by r.Marca,r.data,r.TipSuma) as nrord_poz, r.Data, r.Marca, sn.Indicator, sn.TipSuma, 
		r.TipSuma as TipContributii, sn.suma as salar_net, r.suma as retinere_repartizata, s.sumarepartizata, sn.Explicatii, r.Explicatii as ExplicatiiRetineri, sn.idpoz, r.Numar, r.nrp
	into #retineri
	from #retineriDeRep r
		inner/*left outer*/ join #salarNetPtRep sn on r.Data=sn.Data and r.Marca=sn.Marca and sn.nrp between r.nrmin and r.nrmax and r.nrmin<>0 --and r.Indicator=''
		cross apply (select round((case when r.cumulat<=sn.cumulat then r.cumulat else sn.cumulat end)
						-(case when r.cumulat-r.suma>sn.cumulat-sn.suma then r.cumulat-r.suma else sn.cumulat-sn.suma end),2) as sumarepartizata) s
	/*	Am renuntat pentru moment la a aduce aici separat retinerile cu indicator intrucat nu stiu de ce componenta de brut sa o legam. 
		Poate ar trebui mai sus unde spargem retinerile pe brut sa tinem cont de indicator*/
	/*union all 
	--In al doilea select selectez retinerile cu indicator in dreptul contului creditor. Pentru moment daca contul creditor are indicator, in procedura 
	select row_number() over(order by r.Marca,r.data,r.TipSuma) as nrord_poz, r.Data, r.Marca, r.Indicator, r.TipSuma, 
		r.TipSuma as TipContributii, 0 as salar_net, r.suma as retinere_repartizata, r.suma as sumarepartizata, r.Explicatii, r.Explicatii as ExplicatiiRetineri, r.idpoz, r.Numar, r.nrp
	from #retineriDeRep r
	where r.Indicator<>''*/
	
	order by Data, Marca, nrp
	delete from #retineri where sumarepartizata=0

	if exists (select * from sysobjects where name ='calculOrdonantariSalariiSPRet2')
		exec calculOrdonantariSalariiSPRet2 @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marca, @locm=@locm, @tipCalcul=@tipCalcul
	
	/*	Pun tabela temporara #restplata componentele restului de plata formata din brut, contributii, retineri, fiecare cu semnul corespunzator. La final se vor grupa. */
	select Data, TipSuma, Marca, sum(Suma) as suma, Indicator, Explicatii, 'RESTPLATA' as TipContributii, 'Rest de plata' as ExplicatiiContributii, min(idpoz) as idpoz
	into #restplata
	from #sumeDet
	where tipDate='BRUT' and TipSuma<>'TICHETE' and suma<>0
	group by Data, TipSuma, Marca, Indicator, Explicatii
	union all 
	select Data, TipSuma, Marca, sum(-1*Suma), Indicator, ExplicatiiSuma, 'RESTPLATA', 'Rest de plata', min(idpoz)
	from #contributii
	where suma<>0
	group by Data, TipSuma, Marca, Indicator, ExplicatiiSuma
	union all 
	select Data, TipSuma, Marca, sum(-1*sumarepartizata), Indicator, Explicatii, 'RESTPLATA', 'Rest de plata', min(idpoz)
	from #retineri
	where sumarepartizata<>0 
		and not (@locm<>'' and @locmExceptie='' and @fltLocmChelt=1)	-- daca filtrez un loc de munca de cheltuiala nu iau in calcul retinerile (se vor retine de la functia de baza)
	group by Data, TipSuma, Marca, Indicator, Explicatii
	/* terminat repartizare retineri din salarul net */

	if @tipCalcul=1		-- centralizator contributii pe coduri bugetare
	begin
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma, TipContributii, ExplicatiiContributii)
		select Data, TipSuma, sum(Suma), Indicator, Explicatii, TipContributii, ExplicatiiContributii
		from #restplata
		where suma<>0
		group by Data, TipSuma, Indicator, Explicatii, TipContributii, ExplicatiiContributii

		/* contributiile angajatorului se pun direct in tabela de ordonantari centralizata*/
		/* asigurari sociale - permanenti */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)
		select n.Data, 'CASUNIT', convert(decimal(12,2),sum(n.CasAngajator-b.AjutorDeces)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica-pl1.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #sbrut b on b.data=n.data and b.marca=n.marca
			left outer join #confignc cn on cn.Numar_pozitie=100 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASGRUPA3'
			left outer join #par_lunari pl1 on pl1.data=@datasus and pl1.Parametru='CASINDIV'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca not in ('P','O')
		group by n.data

		/* asigurari sociale - ocazionali */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'CASUNIT_OCAZ', convert(decimal(12,2),sum(n.CasAngajator)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica-pl1.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #confignc cn on cn.Numar_pozitie=102 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASGRUPA3'
			left outer join #par_lunari pl1 on pl1.data=@datasus and pl1.Parametru='CASINDIV'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca in ('P','O')
		group by n.data

		/* asigurari sociale de somaj - permanenti */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'SOMAJUNIT', convert(decimal(12,2),sum(n.SomajAngajator-n.SubventieSomaj))-convert(decimal(12),sum(n.ScutireSomaj)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #confignc cn on cn.Numar_pozitie=105 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='3.5%SOMAJ'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca not in ('P','O')
		group by n.data

		/* asigurari sociale de somaj - ocazionali */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'SOMAJUNIT_OCAZ', convert(decimal(12,2),sum(n.SomajAngajator)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #confignc cn on cn.Numar_pozitie=107 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='3.5%SOMAJ'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca in ('P','O')
		group by n.data

		/* asigurari sociale de sanatate - permanenti */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'CASSUNIT', convert(decimal(12,2),sum(n.CassAngajator)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #confignc cn on cn.Numar_pozitie=110 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASSUNIT'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca not in ('P','O')
		group by n.data

		/* asigurari sociale de sanatate - ocazionali */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'CASSUNIT_OCAZ', convert(decimal(12,2),sum(n.CassAngajator)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #confignc cn on cn.Numar_pozitie=112 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASSUNIT'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca in ('P','O')
		group by n.data

		/* asigurari sociale de sanatate suportate de angajator pentru concedii medicale din cauza de accident de munca (partea suportata de angajator) */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'CASSPTFAAMBP', sum(n.CassPtFaambp) as suma, '' as indicator, 
			'Asigurari santate pt. CM din cauza de acc. de munca '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='CASSIND'
		group by n.data

		/* fondul de accidente de munca si boli profesionale - permanenti */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'FAAMBP', convert(decimal(12,2),sum(n.Faambp-n.CassDinFaambp-n.CCIDinFaambp-b.IndCMFaambp)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #sbrut b on b.data=n.data and b.marca=n.marca
			left outer join #confignc cn on cn.Numar_pozitie=115 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='0.5%ACCM'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca not in ('P','O')
		group by n.data

		/* fondul de accidente de munca si boli profesionale - ocazionali */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'FAAMBP_OCAZ', convert(decimal(12,2),sum(n.Faambp-n.CassDinFaambp-n.CCIDinFaambp-b.IndCMFaambp)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #sbrut b on b.data=n.data and b.marca=n.marca
			left outer join #confignc cn on cn.Numar_pozitie=117 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='0.5%ACCM'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca in ('P','O')
		group by n.data

		/* concedii si indemnizatii - permanenti */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'CCI', convert(decimal(12,2),sum(n.CCI+n.CCIDinFaambp-b.IndCMFnuass)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #sbrut b on b.data=n.data and b.marca=n.marca
			left outer join #confignc cn on cn.Numar_pozitie=120 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='COTACCI'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca not in ('P','O')
		group by n.data

		/* concedii si indemnizatii - ocazionali */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'CCI_OCAZ', convert(decimal(12,2),sum(n.CCI)) as suma, max(isnull(nullif(c.indicator,''),cn.Comanda)) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #sbrut b on b.data=n.data and b.marca=n.marca
			left outer join #confignc cn on cn.Numar_pozitie=120 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='COTACCI'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		where n.Grupa_de_munca in ('P','O')
		group by n.data

		/* fond de garantare */
		insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
		select n.Data, 'FONDGARANTARE', convert(decimal(12,2),sum(n.FondGarantare)) as suma, max(isnull(isnull(nullif(c.indicator,''),cn.Comanda),'')) as indicator, 
			rtrim(max(cn.Denumire))+' '+convert(varchar(10),max(pl.Val_numerica))+'%' as explicatii
		from #cnet n
			left outer join #confignc cn on cn.Numar_pozitie=125 and cn.lm=n.lm
			left outer join #par_lunari pl on pl.data=@datasus and pl.Parametru='FONDGAR'
			left outer join #conturi c on c.cont=cn.Cont_debitor
		group by n.data

		/* contributia pentru neangajare persoane cu handicap */
		if not (@locm is not null and @fltLocmChelt=1)
			insert into #sume (Data, TipSuma, Suma, Indicator, ExplicatiiSuma)	
			select dbo.eom(convert(datetime,substring(p.parametru,4,2)+'/01/'+substring(p.parametru,6,4),102)) as Data, 
				'SOLIDARITATE', p.Val_numerica as suma, isnull(isnull(nullif(c.indicator,''),cn.Comanda),'') as indicator, 
				rtrim(cn.Denumire)+' '+'4%' as explicatii
			from par p
				left outer join config_nc cn on cn.Numar_pozitie=150 and nullif(loc_de_munca,'') is null
				left outer join #conturi c on c.cont=cn.Cont_debitor
			where p.tip_parametru='PS' and p.parametru like 'CPH'+'%' and p.parametru<>'CPH-EGMP'
				and dbo.eom(convert(datetime,substring(p.parametru,4,2)+'/01/'+substring(p.parametru,6,4),102)) between @dataJos and @dataSus

		if @locm<>'' and @fltLocmChelt=1
			update #sume set suma=round(suma,0) where tipSuma in ('CASUNIT','CASSUNIT','SOMAJUNIT','FAAMBP','CCI','FONDGARANTARE')
			
		update #sume set TipContributii=TipSuma, ExplicatiiContributii=ExplicatiiSuma
		where TipContributii is null and ExplicatiiContributii is null

		delete from #sume where convert(decimal(12,2),isnull(suma,0))=0

	end

	/*	apelare procedura specifica care sa altereze tabelele din care se returneaza sumele finale */
	if exists (select * from sysobjects where name ='calculOrdonantariSalariiSP2')
		exec calculOrdonantariSalariiSP2 @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marca, @locm=@locm, @tipCalcul=@tipCalcul

	if @tipCalcul=1
	begin
		select TipSuma, max(ExplicatiiSuma) as Explicatii, right(rtrim(dbo.fn_indbugcupuncte(Indicator)),8) as indicator, max(isnull(ib.Denumire,'NECOMPLETAT')) denindicator, 
			round(isnull(max(CASANGAJAT),0),0) as CASAngajat, round(isnull(max(CASSANGAJAT),0),0) as CASSAngajat, round(isnull(max(SOMAJANGAJAT),0),0) as SomajAngajat, 
			isnull(max(CASUNIT),0)+isnull(max(CASUNIT_OCAZ),0) as CASAngajator, isnull(max(CASSUNIT),0)+isnull(max(CASSUNIT_OCAZ),0) as CASSAngajator, isnull(max(CASSPTFAAMBP),0) as CASSPtFaambp, 
			isnull(max(SOMAJUNIT),0)+isnull(max(SOMAJUNIT_OCAZ),0) as SomajAngajator, 
			isnull(max(FAAMBP),0)+isnull(max(FAAMBP_OCAZ),0) as Faambp, isnull(max(CCI),0)+isnull(max(CCI_OCAZ),0) as CCI, isnull(max(FONDGARANTARE),0) as FondGarantare, 
			round(isnull(max(IMPOZIT),0),0) as Impozit, isnull(max(SOLIDARITATE),0) as Solidaritate, isnull(max(RESTPLATA),0) as RestPlata, 
			isnull(max(CASANGAJAT),0)+isnull(max(CASSANGAJAT),0)+isnull(max(SOMAJANGAJAT),0)+isnull(max(CASUNIT),0)+isnull(max(CASUNIT_OCAZ),0)+isnull(max(CASSUNIT),0)+isnull(max(CASSUNIT_OCAZ),0)
			+isnull(max(CASSPTFAAMBP),0)+isnull(max(SOMAJUNIT),0)+isnull(max(SOMAJUNIT_OCAZ),0)+isnull(max(FAAMBP),0)+isnull(max(FAAMBP_OCAZ),0)
			+isnull(max(CCI),0)+isnull(max(CCI_OCAZ),0)+isnull(max(FONDGARANTARE),0) as AsigurariSociale 
		--into #test
		from (select TipSuma, Indicator, ExplicatiiSuma, TipContributii, sum(suma) as suma, min(idpoz) as idpoz from #sume where TipSuma<>'CORECTIA-R'
			group by TipSuma, Indicator, ExplicatiiSuma, TipContributii) a
				pivot (max(suma) for TipContributii 
					in ([CASANGAJAT],[CASSANGAJAT],[SOMAJANGAJAT],[IMPOZIT],[CASUNIT],[CASUNIT_OCAZ],[CASSUNIT],[CASSUNIT_OCAZ],[CASSPTFAAMBP],[SOMAJUNIT],[SOMAJUNIT_OCAZ],
					[FAAMBP],[FAAMBP_OCAZ],[FONDGARANTARE],[CCI],[CCI_OCAZ],[SOLIDARITATE],[RESTPLATA])) b
			left outer join indbug ib on ib.Indbug=b.Indicator
		group by TipSuma, Indicator
		order by Indicator, min(idpoz)
/*
		select sum(CASANGAJAT) as CASAngajat, sum(CASSANGAJAT) as CASSAngajat, sum(SOMAJANGAJAT) as SomajAngajat, 
			sum(CASANGAJATOR) as CASAngajator, sum(CASSANGAJATOR) as CASSAngajator, sum(SOMAJANGAJATOR) as SomajAngajator, 
			sum(FAAMBP) as Faambp, sum(CCI) as CCI, sum(FONDGARANTARE) as FondGarantare, 
			sum(IMPOZIT) as Impozit, sum(SOLIDARITATE) as Solidaritate, sum(RESTPLATA) as RestPlata
		from #test
*/
	end

	if @tipCalcul=2		-- centralizator rest de plata pe coduri bugetare si banci
	begin
		select rp.Data, p.banca as Banca, rp.TipSuma, sum(rp.Suma) as RestPlata, right(rtrim(dbo.fn_indbugcupuncte(rp.Indicator)),8) as indicator, 
			rp.Explicatii, rp.TipContributii, rp.ExplicatiiContributii
		from #restplata rp
			left outer join personal p on p.Marca=rp.Marca
		where rp.suma<>0 
		group by rp.Data, p.Banca, rp.Indicator, rp.TipSuma, rp.Explicatii, rp.TipContributii, rp.ExplicatiiContributii
		order by rp.Data, p.Banca, rp.indicator, min(rp.idpoz), rp.TipSuma
	end

	if @tipCalcul=3		--	nota contabila contributii angajati
	Begin
		select Data, TipSuma, Marca, lm, Indicator, Suma, ExplicatiiSuma, TipContributii, ExplicatiiContributii, idpoz
		from #contributii
		union all 
		select Data, 'CCIFAAMBP', Marca, lm, '', CCIDinFaambp, '', 'CCIFAAMBP', 'CCI suportat din FAAMBP', 0
		from #cnet
		where CCIDinFaambp<>0
		union all 
		select Data, 'CASSFAAMBP', Marca, lm, '', CassDinFaambp, '', 'CASSFAAMBP', 'C.A.S.S.  suportat din FAAMBP', 0
		from #cnet
		where CassDinFaambp<>0
	End

	if @tipCalcul=4		--	nota contabila retineri angajati din net
	Begin
		select nrord_poz, Data, Marca, Indicator, TipSuma, TipContributii, sumarepartizata, Explicatii, ExplicatiiRetineri, Numar
		from #retineri
	End
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura calculOrdonantariSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

