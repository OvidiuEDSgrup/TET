/* operatie pt. generare NC pt. sume din net (contributii angajat, avans, etc.) */
Create procedure GenNCDinNet
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output, @NumarDoc char(8), 
	@LMSumaIncas decimal(10) output, @LMCOIncasat decimal(10) output, 
	@LMImpozitActivi decimal(10) output, @LMImpozitDanes decimal(10) output, @LMImpozitBoln decimal(10) output, @LMImpozitBolnDanes decimal(10) output, @LMImpozitIpotetic decimal(10) output, 
	@LMImpozitOcazITO decimal(10) output, @LMImpozitOcazITP decimal(10) output, @LMImpozitOcazRO decimal(10) output, 
	@LMCasActivi decimal(10) output, @LMCasOcazPM decimal(10) output, @LMCasOcazPCA decimal(10) output, @LMCasBoln decimal(10) output, 
	@LMSomajActivi decimal(10) output, @LMSomajOcaz decimal(10) output, @LMSomajBoln decimal(10) output, 
	@LMCassActivi decimal(10) output, @LMCassOcazP decimal(10) output, @LMCassOcazO decimal(10) output, @LMCassFaambp decimal(10) output, 
	@LMSumaNeimpActivi decimal(10) output, @LMSumaNeimpBoln decimal(10) output, 
	@LMAvansActivi decimal(10) output, @LMAvansBoln decimal(10) output, @LMAvansOcazO decimal(10) output, @LMAvansOcazP decimal(10) output, 
	@LMSubvSomaj decimal(10) output, @LMCCIFaambp decimal(10) output
As
Begin try
	/*	apelez procedura specifica care sa inlocuiasca procedura standard (Pentru inceput se foloseste la Plexus Oradea, client Angajator) */
	if exists (select * from sysobjects where name ='GenNCDinNetSP' and type='P')
	begin
		exec GenNCDinNetSP @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @Continuare=@Continuare output, @NrPozitie=@NrPozitie output, @NumarDoc=@NumarDoc
		return
	end

	declare @userASiS char(10), @Sub char(9), @OreLuna int, @CasIndiv decimal(5,2), @SomajInd decimal(5,2), @CASSInd decimal(5,2), 
	@Subtipcor int, @DenCorE char(30), @DenCorM char(30), @NCIndBug int, @NCAnActiv int, @NCAnActivCtChelt int, @NCAnActivDebite int, 
	@NCTaxePLM int, @NCTaxePLMCh int, @AnPLImpozit int, @CondAnPLImpozit int,
	@DebitAvansActiv varchar(20), @CreditAvansActiv varchar(20), @MarcaCreditAvans int, 
	@DebitAvansBoln varchar(20), @CreditAvansBoln varchar(20), 
	@DebitAvansOcazO varchar(20), @CreditAvansOcazO varchar(20), @MarcaCreditAvansOcazO int,
	@DebitAvansOcazP varchar(20), @CreditAvansOcazP varchar(20), @MarcaCreditAvansOcazP int,
	@DebitSumeIncas varchar(20), @CreditSumeIncas varchar(20), @MarcaCreditSumeIncas int, 
	@CreditCheltOcazO varchar(20), @CreditCheltOcazP varchar(20), @AtribuireCreditCheltOcazO int, @AtribuireCreditCheltOcazP int, 
	@DebitSomajActivi varchar(20), @CreditSomajActivi varchar(20), @DebitSomajBolnavi varchar(20), @CreditSomajBolnavi varchar(20), 
	@DebitSomajOcaz varchar(20), @CreditSomajOcaz varchar(20), 
	@DebitCASActivi varchar(20), @CreditCASActivi varchar(20), @DebitCASOcaz varchar(20), @CreditCASOcaz varchar(20), 
	@DebitCASBoln varchar(20), @CreditCASBoln varchar(20), 
	@DebitCassActivi varchar(20), @CreditCassActivi varchar(20), @DebitCassOcazO varchar(20), @CreditCassOcazO varchar(20), 
	@DebitCassOcazP varchar(20), @CreditCassOcazP varchar(20), @AtribContDebitCassOcazO int, @AtribContDebitCassOcazP int, 
	@DebitCassFaambp varchar(20), @CreditCassFaambp varchar(20), 
	@DebitImpozitOcazO varchar(20), @CreditImpozitOcazO varchar(20), @DebitImpozitOcazP varchar(20), @CreditImpozitOcazP varchar(20), 
	@DebitIndBug varchar(20), @CreditIndBug varchar(20), 
	@CreditFaambp varchar(20), @CreditCCI varchar(20), 
	@Dafora int, @Somesana int, @NCSomesanaMures int, @Salubris int, @Agrosem int, @Tender int, @Reva int, @NCConsAdmGrpMP int, 
	@Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), @condGrupaM_O int, @condGrupaM_P int, 
	@Data datetime, @Marca char(6), @gMarca char(6), @Numar_doc char(10), @AnActiv varchar(10), @AnActivCAS varchar(10), @AnActivImp varchar(10), 
-- variabile din fetch
	@Grupa_de_munca char(1), @pSomaj_1 int, @As_sanatate decimal(5,2), @Tip_colab char(3), @Adresa char(20), 
	@Judet char(15), @Analitic_impozit char(10), @Venit_total decimal(10), @Co_incasat decimal(10), @Suma_incasata decimal(10),
	@Suma_neimpozabila decimal(10), @Diferenta_impozit decimal(10), @Impozit decimal(10), @ImpozitIpotetic decimal(10), @Cas_individual decimal(10),
	@Cas_bolnavi decimal(10), @Somaj_1 decimal(10), @Asig_sanatate_din_impozit decimal(10), @Asig_sanatate_din_net decimal(10), 
	@Asig_sanatate_din_CAS decimal(10), @Avans decimal(10), @Ven_net_in_imp decimal(10), @Ded_somaj decimal(10), @CCI_Faambp decimal(10), 
	@SalBolnav int, @CMUnitate decimal(10), @CMCas decimal(10), 
	@Activitate varchar(10), @Cont_debitor varchar(20), @Cont_creditor varchar(20), 
	@Sold_credit decimal(12,2), @Grup_marca char(9), @Sortare_lm varchar(20), 
	@Sortare_CF decimal(10), @IndBug char(20), @Lm char(9), @vLm char(20), @gLm char(9), @LmDoc char(9), 
-- variabile pt. Salubris repartizare sume din 421 si 423
	@CreditCMUnitate1 varchar(20), @CreditCMCas1 varchar(20), 
	@DebitImpozitActivi varchar(20), @CreditImpozitActivi varchar(20), @DebitImpozitBolnavi varchar(20), @CreditImpozitBolnavi varchar(20), @DebitImpozitIpotetic varchar(20), @CreditImpozitIpotetic varchar(20), 
	@CreditChelt varchar(20), @SomajLucrat decimal(10,2), @SomajCMUnitate decimal(10,2), @SomajCMCas decimal(10,2), 
	@ImpozitActivi decimal(10,2), @ImpozitBolnavi decimal(10,2), @ImpozitLucrat decimal(10,2), @ImpozitCMUnitate decimal(10,2), @ImpozitCMCas decimal(10,2), @CMNeimpozabil decimal(10,2),
	@gfetch int

	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @CasIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @SomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @CASSInd=dbo.iauParLN(@dataSus,'PS','CASSIND')
	set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTaxePLM=dbo.iauParL('PS','N-C-TX-LM')
	set @NCTaxePLMCh=dbo.iauParL('PS','N-C-TXLMC')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivDebite=dbo.iauParN('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')
	set @AnPLImpozit=dbo.iauParL('PS','AN-PL-IMP')
	set @DebitAvansActiv=dbo.iauParA('PS','N-AV-ACTD')
	set @CreditAvansActiv=dbo.iauParA('PS','N-AV-ACTC')
	set @MarcaCreditAvans=dbo.iauParL('PS','N-AV-ACTC')
	set @DebitAvansBoln=dbo.iauParA('PS','N-AV-BOLD')
	set @CreditAvansBoln=dbo.iauParA('PS','N-AV-BOLC')
	set @DebitAvansOcazO=dbo.iauParA('PS','N-AV-COLD')
	set @CreditAvansOcazO=dbo.iauParA('PS','N-AV-COLC')
	set @MarcaCreditAvansOcazO=dbo.iauParL('PS','N-AV-COLC')
	set @DebitAvansOcazP=dbo.iauParA('PS','N-AV-CLPD')
	set @CreditAvansOcazP=dbo.iauParA('PS','N-AV-CLPC')
	set @MarcaCreditAvansOcazP=dbo.iauParL('PS','N-AV-CLPC')
	set @DebitSumeIncas=dbo.iauParA('PS','N-AV-RIDD')
	set @CreditSumeIncas=dbo.iauParA('PS','N-AV-RIDC')
	set @MarcaCreditSumeIncas=dbo.iauParL('PS','N-AV-RIDC')
	set @CreditCheltOcazO=dbo.iauParA('PS','N-C-SAL2C')
	set @CreditCheltOcazP=dbo.iauParA('PS','N-C-SAL3C')
	select @AtribuireCreditCheltOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazO
	select @AtribuireCreditCheltOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazP
	set @DebitSomajActivi=dbo.iauParA('PS','N-ASSJ1AD')
	set @CreditSomajActivi=dbo.iauParA('PS','N-ASSJ1AC')
	set @DebitSomajBolnavi=dbo.iauParA('PS','N-ASSJ1BD')
	set @CreditSomajBolnavi=dbo.iauParA('PS','N-ASSJ1BC')
	set @DebitSomajOcaz=dbo.iauParA('PS','N-ASSJ1OD')
	set @CreditSomajOcaz=dbo.iauParA('PS','N-ASSJ1OC')
	set @DebitCASActivi=dbo.iauParA('PS','N-AS-P3AD')
	set @CreditCASActivi=dbo.iauParA('PS','N-AS-P3AC')
	set @DebitCASOcaz=dbo.iauParA('PS','N-AS-P3OD')
	set @CreditCASOcaz=dbo.iauParA('PS','N-AS-P3OC')
	set @DebitCASBoln=dbo.iauParA('PS','N-AS-P3BD')
	set @CreditCASBoln=dbo.iauParA('PS','N-AS-P3BC')
	set @DebitCassActivi=dbo.iauParA('PS','N-ASNEAD')
	set @CreditCassActivi=dbo.iauParA('PS','N-ASNEAC')
	set @DebitCassOcazO=dbo.iauParA('PS','N-ASNEOD')
	set @CreditCassOcazO=dbo.iauParA('PS','N-ASNEOC')
	set @DebitCassOcazP=dbo.iauParA('PS','N-ASNEOPD')
	set @CreditCassOcazP=dbo.iauParA('PS','N-ASNEOPC')
	select @AtribContDebitCassOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazO
	select @AtribContDebitCassOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazP
	set @DebitCassFaambp=dbo.iauParA('PS','N-ASFABPD')
	set @CreditCassFaambp=dbo.iauParA('PS','N-ASFABPC')
	set @DebitImpozitActivi=dbo.iauParA('PS','N-I-PMACD')
	set @CreditImpozitActivi=dbo.iauParA('PS','N-I-PMACC')
	set @DebitImpozitBolnavi=dbo.iauParA('PS','N-I-PMBOD')
	set @CreditImpozitBolnavi=dbo.iauParA('PS','N-I-PMBOC')
	set @DebitImpozitIpotetic=dbo.iauParA('PS','N-I-IPPMD')
	set @CreditImpozitIpotetic=dbo.iauParA('PS','N-I-IPPMC')
	set @DebitImpozitOcazO=dbo.iauParA('PS','N-I-OCAZD')
	set @CreditImpozitOcazO=dbo.iauParA('PS','N-I-OCAZC')
	set @DebitImpozitOcazP=dbo.iauParA('PS','N-I-OCZPD')
	set @CreditImpozitOcazP=dbo.iauParA('PS','N-I-OCZPC')
	set @CreditFaambp=dbo.iauParA('PS','N-AS-FR1C')
	set @CreditCCI=dbo.iauParA('PS','N-AS-CCIC')
	set @CreditChelt=dbo.iauParA('PS','N-C-SAL1C')
	set @CreditCMUnitate1=dbo.iauParA('PS','N-C-CMU1C')
	set @CreditCMCas1=dbo.iauParA('PS','N-C-CMC1C')

	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Agrosem=dbo.iauParL('SP','AGROSEM')
	set @Tender=dbo.iauParL('SP','TENDER')
	set @Reva=dbo.iauParL('SP','REVA')
	set @NCSomesanaMures=dbo.iauParL('PS','NC-SMURES')
	set @NCConsAdmGrpMP=dbo.iauParL('PS','NC-ADM-GP')
	set @CondAnPLImpozit=(case when @Agrosem=1 or @Tender=1 or @AnPLImpozit=1 then 1 else 0 end)
	set @DenCorM=''
	set @IndBug=''
	select @DenCorM=Denumire from tipcor where tip_corectie_venit='M-'

	if object_id('tempdb..#impozitIpotetic') is not null drop table #impozitIpotetic

-->	selectez din extinfop, pozitia pentru salariatii care au impozit ipotetic (HG84/2013) valabila la luna curenta. Acest impozit ipotetic se va conta separat.
	create table #impozitIpotetic (data datetime, marca varchar(6), ImpozitIpotetic varchar(100))
	insert into #impozitIpotetic 
	select data, marca, ImpozitIpotetic 
	from dbo.fSalariatiCuImpozitIpotetic (@dataJos, @dataSus, @lm, null)

	declare NCDinNet cursor for
	select a.Data, a.Marca, (case when 1=0 then i.Loc_de_munca else a.Loc_de_munca end) as Loc_de_munca, 
		isnull(i.Grupa_de_munca,p.Grupa_de_munca), p.Somaj_1, p.As_sanatate, isnull(i.Tip_colab,p.Tip_colab), p.Adresa, isnull(i.Judet,p.Judet), 
		(case when @CondAnPLImpozit=1 then ltrim(substring(isnull(i.Judet,p.Judet),charindex(',',isnull(i.Judet,p.Judet))+1,10)) else '' end) as Analitic_impozit,
		a.VENIT_TOTAL, a.CO_incasat, (case when @NCTaxePLMCh=1 then 0 else a.Suma_incasata end), a.Suma_neimpozabila, (case when 1=0 then a.Diferenta_impozit else 0 end), 
		(case when @NCTaxePLMCh=1 or upper(isnull(ii.ImpozitIpotetic,0))='DA' then 0 else a.Impozit+(case when 1=1 then a.Diferenta_impozit else 0 end) end), 
		(case when upper(isnull(ii.ImpozitIpotetic,0))='DA' then a.Impozit+a.Diferenta_impozit else 0 end), 
		isnull((case when @NCTaxePLMCh=1 then 0 else a.Pensie_suplimentara_3-round((n.Baza_CAS_cond_norm+n.Baza_CAS_cond_deoseb+n.Baza_CAS_cond_spec)*@CasIndiv/100,0) end),0), 
		isnull((case when @NCTaxePLMCh=1 then 0 else round((n.Baza_CAS_cond_norm+n.Baza_CAS_cond_deoseb+n.Baza_CAS_cond_spec)*@CasIndiv/100,0) end),0) as Cas_bolnavi, 
		(case when @NCTaxePLMCh=1 then 0 else a.Somaj_1 end), a.Asig_sanatate_din_impozit, 
		(case when @NCTaxePLMCh=1 then 0 else a.Asig_sanatate_din_net end), a.Asig_sanatate_din_CAS, 
		a.Avans+a.Premiu_la_avans, a.VEN_NET_IN_IMP, a.Chelt_prof, isnull(n.Ded_suplim,0), 
		(case when @AnPLImpozit=1 then a.Marca else '' end) as Grup_marca, 
		(case when @NCAnActiv=1 then p.Activitate else '' end) as Activitate, 
		(case when isnull(bm.Ore_concediu_medical,0)>=@OreLuna/8*(case when i.grupa_de_munca='C' then isnull(bm.Spor_cond_10,8) else 8 end) then 1 else 0 end), 
		isnull(bm.Ind_c_medical_unitate+bm.CMunitate,0) as CMUnitate, isnull(bm.Ind_c_medical_cas+bm.CMcas+bm.Spor_cond_9,0) as CMCas, isnull(cm.CMNeimpozabil,0) as CMNeimpozabil
	from #net a
		left outer join personal p on p.marca=a.marca
		left outer join infopers f on f.marca=a.marca
		left outer join istpers i on i.marca=a.marca and i.data=a.data
		left outer join #net n on n.data=dbo.bom(a.data) and n.marca=a.marca
		left outer join #brutMarca bm on bm.data=a.data and bm.marca=a.marca
		left outer join #impozitIpotetic ii on ii.Marca=a.Marca
		left outer join (select Data, Marca, sum(Indemnizatie_CAS) as CMNeimpozabil from conmed 
			where data=@dataSus and tip_diagnostic in ('8-','9-','15') group by Data, Marca) cm on (@Salubris=1 or 1=1) and a.Data=cm.Data and a.Marca=cm.Marca
	where a.data=@dataSus and (@pMarca='' or a.marca=@pMarca) and (@NCSomesanaMures=0 or i.loc_de_munca between '40' and '40'+'ZZZ') 
		and a.Data>=p.Data_angajarii_in_unitate
	union all
	select @dataSus, a.Marca, a.Loc_de_munca as Loc_de_munca, i.Grupa_de_munca, p.Somaj_1, p.As_sanatate, i.Tip_colab, p.Adresa, i.Judet, 
		(case when @CondAnPLImpozit=1 then ltrim(substring(i.Judet,charindex(',',i.Judet)+1,10)) else '' end) as Analitic_impozit, 0, 0, 0, 0, 0, 
		a.Impozit, 0, a.CAS_individual-(case when a.Loc_de_munca=b.Loc_de_munca and Convert(int,b.Loc_munca_pt_stat_de_plata)=1
			then round((n.Baza_CAS_cond_norm+n.Baza_CAS_cond_deoseb+n.Baza_CAS_cond_spec)*@CasIndiv/100,0) else 0 end), 
		(case when a.Loc_de_munca=b.Loc_de_munca and Convert(int,b.Loc_munca_pt_stat_de_plata)=1
			then round((n.Baza_CAS_cond_norm+n.Baza_CAS_cond_deoseb+n.Baza_CAS_cond_spec)*@CasIndiv/100,0) else 0 end) as Cas_bolnavi, 
		a.Somaj_1, 0, a.Asig_sanatate_din_net, 0, 0, 0, 0, 0, 
		(case when @AnPLImpozit=1 then a.Marca else '' end) as Grup_marca, 
		(case when @NCAnActiv=1 then p.Activitate else '' end) as Activitate, 
		(case when isnull(bm.Ore_concediu_medical,0)>=@OreLuna/8*(case when i.grupa_de_munca='C' then isnull(bm.Spor_cond_10,8) else 8 end) then 1 else 0 end) as Salariat_bolnav, 0, 0, 0 
	from casbrut a
		left outer join personal p on p.marca=a.marca
		left outer join infopers f on f.marca=a.marca
		left outer join istpers i on i.marca=a.marca and i.data=@dataSus
		left outer join #brut b on b.data=i.data and b.marca=a.marca and b.loc_de_munca=a.loc_de_munca
		left outer join #brutMarca bm on bm.data=@dataSus and bm.marca=a.marca
		left outer join #net n on n.data=dbo.bom(i.data) and n.marca=a.marca
	where @NCTaxePLMCh=1 and (@pMarca='' or a.marca=@pMarca) and @NCSomesanaMures=0 and p.Data_angajarii_in_unitate<=@dataSus
	union all
	select a.Data, a.Marca, a.Loc_de_munca as Loc_de_munca, i.Grupa_de_munca, 0, 0, i.Tip_colab, p.Adresa, i.Judet, '' as Analitic_impozit,
		0, 0, a.Suma_corectie, 0, 0, 0, 0, 0, 0 as Cas_bolnavi, 
		0, 0, 0, 0, 0, 0, 0, 0, (case when @AnPLImpozit=1 then a.Marca else '' end) as Grup_marca, 
		(case when @NCAnActiv=1 then p.Activitate else '' end) as Activitate, 0, 0, 0, 0
	from corectii a
		left outer join personal p on p.marca=a.marca
		left outer join infopers f on f.marca=a.marca
		left outer join istpers i on i.marca=a.marca and i.data=a.data
		left outer join #net n on n.data=dbo.bom(a.data) and n.marca=a.marca
	where @NCTaxePLMCh=1 and a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca) 
		and @NCSomesanaMures=0 and a.Data>=p.Data_angajarii_in_unitate 
		and (@Subtipcor=0 and a.Tip_corectie_venit='M-' or @Subtipcor=1 and a.tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit='M-'))
	order by Analitic_impozit, Activitate, Loc_de_munca

open NCDinNet
fetch next from NCDinNet into @Data, @Marca, @Lm, @Grupa_de_munca, @pSomaj_1, @As_sanatate, @Tip_colab, @Adresa, @Judet, 
	@Analitic_impozit, @VENIT_TOTAL, @CO_incasat, @Suma_incasata, @Suma_neimpozabila, @Diferenta_impozit, @Impozit, @ImpozitIpotetic, @Cas_individual, 
	@Cas_bolnavi, @Somaj_1, @Asig_sanatate_din_impozit, @Asig_sanatate_din_net, @Asig_sanatate_din_CAS, @Avans, @VEN_NET_IN_IMP, @Ded_somaj, 
	@CCI_Faambp, @Grup_marca, @Activitate, @SalBolnav, @CMUnitate, @CMCas, @CMNeimpozabil
Set @gfetch=@@fetch_status
Set @gMarca=@Marca
Set @gLm=@Lm
Set @LmDoc=@Lm
While @gfetch = 0 
Begin
	select @LMSumaIncas=0, @LMCOIncasat=0, @LMImpozitActivi=0, @LMImpozitDanes=0, @LMImpozitBoln=0, @LMImpozitBolnDanes=0, @LMImpozitIpotetic=0, 
		@LMImpozitOcazITO=0, @LMImpozitOcazITP=0, @LMImpozitOcazRO=0, 
		@LMCasActivi=0, @LMCasOcazPM=0, @LMCasOcazPCA=0, @LMCasBoln=0, 
		@LMSomajActivi=0, @LMSomajOcaz=0, @LMSomajBoln=0, @LMCassActivi=0, @LMCassOcazP=0, 
		@LMCassOcazO=0, @LMCassFaambp=0, @LMSumaNeimpActivi=0, @LMSumaNeimpBoln=0, @LMAvansActivi=0, @LMAvansBoln=0, 
		@LMAvansOcazO=0, @LMAvansOcazP=0, @LMSubvSomaj=0, @LMCCIFaambp=0
	where @Somesana=1 or @NCTaxePLM=1
	select @SomajLucrat=0, @SomajCMUnitate=0, @SomajCMCas=0, @ImpozitActivi=0, @ImpozitBolnavi=0, @ImpozitLucrat=0, @ImpozitCMUnitate=0, @ImpozitCMcas=0
	where @NCTaxePLM=1 or @Salubris=1 or 1=1

	while @gLm = @Lm and @gfetch = 0
	Begin
		set @AnActiv=(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(@Activitate) else '' end)
		set @AnActivCAS=@AnActiv
		set @AnActivImp=(case when @CondAnPLImpozit=1 then '.'+rtrim(@Analitic_impozit) else @AnActiv end)
		if @Salubris=1
		Begin
			if @DebitSomajActivi<>@DebitSomajBolnavi and @DebitSomajBolnavi=@CreditCMUnitate1
				Set @SomajCMUnitate=(case when @Venit_total=0 then 0 else round(@Somaj_1*@CMUnitate/@Venit_total,0) end)
			if @DebitSomajActivi<>@DebitSomajBolnavi and @DebitSomajBolnavi=@CreditCMCas1
				Set @SomajCMCas=0
				Set @SomajLucrat=@Somaj_1-@SomajCMUnitate-@SomajCMCas
			if @DebitImpozitActivi<>@DebitImpozitBolnavi and @DebitImpozitBolnavi=@CreditCMUnitate1
				Set @ImpozitCMUnitate=(case when @Ven_net_in_imp=0 then 0 else round((@CMUnitate-@SomajCMUnitate)*@Impozit/@Ven_net_in_imp,0) end)
			if @DebitImpozitActivi<>@DebitImpozitBolnavi and @DebitImpozitBolnavi=@CreditCMCas1
				Set @ImpozitCMcas=(case when @Ven_net_in_imp=0 then 0 else round((@CMCas-@CMNeimpozabil-@SomajCMCas)*@Impozit/@Ven_net_in_imp,0) end)
			Set @ImpozitLucrat=@Impozit-@ImpozitCMUnitate-@ImpozitCMcas
		End
		set @LMSumaIncas=@LMSumaIncas+@Suma_incasata+(case when @Salubris=0 and @NCIndBug=0 then @CO_incasat else 0 end)
		select @LMCOIncasat=@LMCOIncasat+@CO_incasat where @NCIndBug=1 
--	impozit
		if not(@Grupa_de_munca in ('O','P')) and (@Dafora=0 or @Lm not in ('10102','10101'))
		Begin
			if @Salubris=0
			begin
				if @DebitImpozitActivi<>@DebitImpozitBolnavi and @DebitImpozitBolnavi=@CreditCMUnitate1
					Set @ImpozitCMUnitate=(case when @Venit_total-@CMNeimpozabil=0 then 0 else round(@Impozit*(@CMUnitate)/(@Venit_total-@CMNeimpozabil),0) end)
				if @DebitImpozitActivi<>@DebitImpozitBolnavi and @DebitImpozitBolnavi=@CreditCMCas1
					Set @ImpozitCMcas=(case when @Venit_total-@CMNeimpozabil=0 then 0 else round(@Impozit*(@CMCas-@CMNeimpozabil)/(@Venit_total-@CMNeimpozabil),0) end)
				Set @ImpozitLucrat=@Impozit-@ImpozitCMUnitate-@ImpozitCMcas
			end
			select @ImpozitActivi=(case when @Salubris=1 or 1=1 then @ImpozitLucrat when @SalBolnav=0 then @Impozit+@Diferenta_impozit else 0 end), 
				@ImpozitBolnavi=(case when @Salubris=1 or 1=1 then @ImpozitCMUnitate+@ImpozitCMCas when @SalBolnav=1 then @Impozit+@Diferenta_impozit else 0 end)
			set @LMImpozitActivi=@LMImpozitActivi+@ImpozitActivi
			set @LMImpozitBoln=@LMImpozitBoln+@ImpozitBolnavi
		End	
		set @LMImpozitIpotetic=@LMImpozitIpotetic+@ImpozitIpotetic
		if not(@Grupa_de_munca in ('O','P')) and @Dafora=1 and @Lm in ('10102','10101')
		Begin
			set @LMImpozitDanes=@LMImpozitDanes+(case when @SalBolnav=0 then @Impozit+@Diferenta_impozit else 0 end)
			set @LMImpozitBolnDanes=@LMImpozitBolnDanes+(case when @SalBolnav=1 then @Impozit+@Diferenta_impozit else 0 end)
		End	
		select @condGrupaM_O=(case when (@Grupa_de_munca='O' 
				or @Grupa_de_munca='P' and (year(@data)>=2011 and @Tip_colab='AS5' or year(@data)>=2012 and @Tip_colab='AS2') and @NCIndBug=0 and @NCConsAdmGrpMP=0) then 1 else 0 end), 
			@condGrupaM_P=(case when @Grupa_de_munca='P' and (not(year(@data)>=2011 and @Tip_colab='AS5' or year(@data)>=2012 and @Tip_colab='AS2') or @NCConsAdmGrpMP=1 or @NCIndBug=1) then 1 else 0 end)
		if @condGrupaM_O=1
			set @LMImpozitOcazITO=@LMImpozitOcazITO+@Impozit+@Diferenta_impozit
		if @condGrupaM_P=1
			set @LMImpozitOcazITP=@LMImpozitOcazITP+@Impozit+@Diferenta_impozit
--	cas individual
		set @LMCasActivi=@LMCasActivi+(case when not(@Grupa_de_munca in ('O','P')) then @Cas_individual else 0 end)
		set @LMCasOcazPM=@LMCasOcazPM+(case when @condGrupaM_P=1 then @Cas_individual else 0 end)
		set @LMCasOcazPCA=@LMCasOcazPCA+(case when @condGrupaM_O=1 then @Cas_individual else 0 end)
		set @LMCasBoln=@LMCasBoln+@Cas_bolnavi
--	somaj individual: (Lucian: 26.07.2013) salariat bolnav era acea persoana aflata toata luna in CM. 
--	Acum somaj bolnav se determina prin aplicare procent somaj la valoarea indemnizatiei de CM suportate de unitate; pt. Salubris am lasat sa se calculeze cum a fost la ei
		if @Salubris=0
		begin
			if @DebitSomajActivi<>@DebitSomajBolnavi and @DebitSomajBolnavi=@CreditCMUnitate1
				Set @SomajCMUnitate=(case when @Venit_total=0 then 0 else round(@CMUnitate*(case when @pSomaj_1<>0 then @SomajInd/100 else 0 end),0) end)
			Set @SomajLucrat=@Somaj_1-@SomajCMUnitate
		end
		if not(@Grupa_de_munca in ('O','P'))
			select @LMSomajActivi=@LMSomajActivi+(case when @Salubris=1 or 1=1 then @SomajLucrat when @SalBolnav=0 then @Somaj_1 else 0 end)
		if @Grupa_de_munca in ('O','P')
			set @LMSomajOcaz=@LMSomajOcaz+(case when @Salubris=1 or 1=1 then @SomajLucrat when @SalBolnav=0 then @Somaj_1 else 0 end)
		set @LMSomajBoln=@LMSomajBoln+(case when @Salubris=1 or 1=1 then @SomajCMUnitate when @SalBolnav=1 then @Somaj_1 else 0 end)
--	asigurari de sanatate
		set @LMCassActivi=@LMCassActivi+(case when not(@Grupa_de_munca in ('O','P')) then @Asig_sanatate_din_net else 0 end)
		set @LMCassOcazO=@LMCassOcazO+(case when /*@SalBolnav=0 and*/ @condGrupaM_O=1 then @Asig_sanatate_din_net else 0 end)
		set @LMCassOcazP=@LMCassOcazP+(case when /*@SalBolnav=0 and*/ @condGrupaM_P=1 then @Asig_sanatate_din_net else 0 end)
		set @LMCassFaambp=@LMCassFaambp+@Asig_sanatate_din_impozit

		set @LMSumaNeimpActivi=@LMSumaNeimpActivi+(case when @SalBolnav=0 then @Suma_neimpozabila else 0 end)
		set @LMSumaNeimpBoln=@LMSumaNeimpBoln+(case when @SalBolnav=1 then @Suma_neimpozabila else 0 end)
--	avans
		if not(@Grupa_de_munca in ('O','P'))
		Begin
			set @LMAvansActivi=@LMAvansActivi+(case when @SalBolnav=0 then @Avans else 0 end)
			set @LMAvansBoln=@LMAvansBoln+(case when @SalBolnav=1 then @Avans else 0 end)
		End	
		if @Grupa_de_munca='O'
			set @LMAvansOcazO=@LMAvansOcazO+@Avans
		if @Grupa_de_munca='P'
			set @LMAvansOcazP=@LMAvansOcazP+@Avans
		set @LMSubvSomaj=@LMSubvSomaj+@Ded_Somaj
		set @LMCCIFaambp=@LMCCIFaambp+@CCI_Faambp
--	NC pe marci
		Set @ContCreditor=rtrim(@CreditAvansActiv)+'.'+rtrim(@Marca)
		Set @Explicatii='Avans angajat - marca '+@Marca
		Set @vLm=(case when @NCTaxePLM=1 then @Lm else '' end)
		if not(@Grupa_de_munca in ('O','P')) and @MarcaCreditAvans=1 and @SalBolnav=0 and @Continuare=1 
		Begin
			exec scriuNCsalarii @Data, @DebitAvansActiv, @ContCreditor, @Avans, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @Lm, '', '', 0, '', '', 0
		End
		if @Grupa_de_munca in ('O','P')
		Begin
			Set @ContCreditor=rtrim(@CreditAvansOcazO)+(case when @MarcaCreditAvansOcazO=1 then '.'+rtrim(@Marca) else '' end)
			Set @Explicatii='Avans angajat colab - marca '+@Marca
			if @Grupa_de_munca='O' and (@MarcaCreditAvansOcazO=1 or @AtribuireCreditCheltOcazO=1) and @SalBolnav=0 and @Continuare=1 
				exec scriuNCsalarii @Data, @DebitAvansOcazO, @ContCreditor, @Avans, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0
			Set @ContCreditor=rtrim(@CreditAvansOcazP)+(case when @MarcaCreditAvansOcazP=1 then '.'+rtrim(@Marca) else '' end)
			if @Grupa_de_munca='P' and (@MarcaCreditAvansOcazP=1 or @AtribuireCreditCheltOcazP=1) and @SalBolnav=0 and @Continuare=1 
				exec scriuNCsalarii @Data, @DebitAvansOcazP, @ContCreditor, @Avans, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0

			Set @Explicatii='Asigurari CAS individual '+rtrim(convert(char(6),@CasIndiv))+'% ocazionali - marca '+@Marca
			if @AtribuireCreditCheltOcazP=1 and @Grupa_de_munca='P' and @Continuare=1
				exec scriuNCsalarii @Data, @CreditCheltOcazP, @CreditCASOcaz, @Cas_individual, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0
			if @AtribuireCreditCheltOcazO=1 and @Grupa_de_munca='O' and @Continuare=1
				exec scriuNCsalarii @Data, @CreditCheltOcazO, @CreditCASOcaz, @Cas_individual, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0

			Set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% ocazionali - marca '+@Marca
			if @AtribuireCreditCheltOcazP=1 and @Continuare=1
				exec scriuNCsalarii @Data, @DebitSomajOcaz, @CreditSomajOcaz, @Somaj_1, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0

			Set @ContDebitor=rtrim(@DebitCassOcazO)+rtrim(@AnActivCAS)
			Set @ContCreditor=rtrim(@CreditCassOcazO)+rtrim(@AnActiv)
			Set @Explicatii='Asig. de sanatate '+rtrim(convert(char(6),@CASSInd))+'% ocaz. - marca '+@Marca
			if @AtribContDebitCassOcazO=1 and @Grupa_de_munca='O' and @Continuare=1
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Asig_sanatate_din_net, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0

			Set @ContDebitor=rtrim(@DebitCassOcazP)+rtrim(@AnActivCAS)
			Set @ContCreditor=rtrim(@CreditCassOcazP)+rtrim(@AnActiv)
			if @AtribContDebitCassOcazP=1 and @Grupa_de_munca='P' and @Continuare=1
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Asig_sanatate_din_net, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0

			Set @ContDebitor=rtrim(@DebitImpozitOcazO)+rtrim(@AnActiv)
			Set @ContCreditor=rtrim(@CreditImpozitOcazO)+rtrim(@AnActivImp)
			Set @Explicatii='Impozit ocazionali - marca '+@Marca
			if (@AtribContDebitCassOcazO=1 or @AnPLImpozit=1) and @condGrupaM_O=1/*@Grupa_de_munca='O'*/ and @Continuare=1
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Impozit, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0

			Set @ContDebitor=rtrim(@DebitImpozitOcazP)+rtrim(@AnActiv)
			Set @ContCreditor=rtrim(@CreditImpozitOcazP)+rtrim(@AnActivImp)
			if (@AtribContDebitCassOcazP=1 or @AnPLImpozit=1) and @condGrupaM_P=1/*@Grupa_de_munca='P'*/ and @Continuare=1
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Impozit, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, @Marca, '', 0
		End
--		Impozit dus pe analitic punct de lucru
		if @AnPLImpozit=1 and not(@grupa_de_munca in ('O','P')) and @Continuare=1
		begin	
			set @ContDebitor=rtrim(@DebitImpozitActivi)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditImpozitActivi)+rtrim(@AnActivImp)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @ImpozitActivi, @NumarDoc, 
			'Impozit personal permanenti - activi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			set @ContDebitor=rtrim(@DebitImpozitBolnavi)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditImpozitBolnavi)+rtrim(@AnActivImp)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @ImpozitBolnavi, @NumarDoc, 
			'Impozit personal permanenti - bolnavi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		end

		Set @ContCreditor=rtrim(@CreditAvansBoln)+'.'+rtrim(@Marca)
		Set @Explicatii='Avans angajat - marca '+@Marca
		if @MarcaCreditAvans=1 and @SalBolnav=1 and @Continuare=1 
		Begin
			exec scriuNCsalarii @Data, @DebitAvansBoln, @ContCreditor, @Avans, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		End
		Set @ContCreditor=rtrim(@CreditSumeIncas)+'.'+rtrim(@Marca)
		Set @Explicatii='Suma incasata - marca '+@Marca
		if @MarcaCreditSumeIncas=1 and @Continuare=1 
		Begin
			exec scriuNCsalarii @Data, @DebitSumeIncas, @ContCreditor, @Suma_incasata, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		End

		fetch next from NCDinNet into @Data, @Marca, @Lm, @Grupa_de_munca, @pSomaj_1, @As_sanatate, @Tip_colab, @Adresa, @Judet, 
			@Analitic_impozit, @VENIT_TOTAL, @CO_incasat, @Suma_incasata, @Suma_neimpozabila, @Diferenta_impozit, @Impozit, @ImpozitIpotetic, @Cas_individual, 
			@Cas_bolnavi, @Somaj_1, @Asig_sanatate_din_impozit, @Asig_sanatate_din_net, @Asig_sanatate_din_CAS, @Avans, @VEN_NET_IN_IMP, @Ded_somaj, 
			@CCI_Faambp, @Grup_marca, @Activitate, @SalBolnav, @CMUnitate, @CMCas, @CMNeimpozabil 
	set @gfetch=@@fetch_status
	End
--	NC pe locuri de munca
	if @Somesana=1 or @NCTaxePLM=1 
	Begin
		if @Continuare=1 and @MarcaCreditAvans=0
		Begin
			Set @ContDebitor=rtrim(@DebitAvansActiv)+rtrim(@AnActiv)
			Set @ContCreditor=rtrim(@CreditAvansActiv)+rtrim(@AnActiv)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMAvansActivi, @NumarDoc, 
			'Avans angajati - activi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			Set @ContDebitor=rtrim(@DebitAvansBoln)+rtrim(@AnActiv)
			Set @ContCreditor=rtrim(@CreditAvansBoln)+rtrim(@AnActiv)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMAvansBoln, @NumarDoc, 
			'Avans angajati - bolnavi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		End
		Set @ContDebitor=rtrim(@DebitAvansOcazO)+rtrim(@AnActiv)
		Set @ContCreditor=rtrim(@CreditAvansOcazO)+rtrim(@AnActiv)
		Set @Explicatii='Avans angajati - colab'
		if @Continuare=1 and @MarcaCreditAvansOcazO=0 and @AtribuireCreditCheltOcazO<>1
		Begin
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMAvansOcazO, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		End
		Set @ContDebitor=rtrim(@DebitAvansOcazP)+rtrim(@AnActiv)
		Set @ContCreditor=rtrim(@CreditAvansOcazP)+rtrim(@AnActiv)
		Set @Explicatii='Avans angajati - colab'
		if @Continuare=1 and @MarcaCreditAvansOcazP=0 and @AtribuireCreditCheltOcazP<>1
		Begin
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMAvansOcazP, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		End
		if @Continuare=1
		Begin
--			Cas individual
			Set @ContDebitor=rtrim(@DebitCASActivi)+rtrim(@AnActiv)
			Set @ContCreditor=rtrim(@CreditCASActivi)+rtrim(@AnActiv)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCasActivi, @NumarDoc, 
			'Asigurari CAS individual - activi perm.', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			Set @ContDebitor=rtrim(@DebitCASBoln)+rtrim(@AnActiv)
			Set @ContCreditor=rtrim(@CreditCASBoln)+rtrim(@AnActiv)

			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCasBoln, @NumarDoc, 
			'Asigurari CAS individual - bolnavi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
--			Set @ContDebitor=rtrim(@DebitCASOcaz)+rtrim(@AnActivCAS)
--			format cont debitor CAS ocazionali P pornind de la contul creditor al cheltuielii
			if @AtribuireCreditCheltOcazP<>1
			Begin
				Set @ContDebitor=rtrim(@CreditCheltOcazP)+rtrim(@AnActivCAS)
				Set @ContCreditor=rtrim(@CreditCASOcaz)+rtrim(@AnActiv)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCasOcazPM, @NumarDoc, 
				'Asigurari CAS individual - ocazionali', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End
			if @AtribuireCreditCheltOcazO<>1
			Begin
				Set @ContDebitor=rtrim(@CreditCheltOcazO)+rtrim(@AnActivCAS)
				Set @ContCreditor=rtrim(@CreditCASOcaz)+rtrim(@AnActiv)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCasOcazPCA, @NumarDoc, 
				'Asigurari CAS individual - ocazionali', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End
--			Somaj individual
			set @ContDebitor=rtrim(@DebitSomajActivi)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditSomajActivi)+rtrim(@AnActiv)
			set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% - activi'
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSomajActivi, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			if @AtribContDebitCassOcazO<>1
			Begin
				set @ContDebitor=rtrim(@DebitSomajOcaz)+rtrim(@AnActiv)
				set @ContCreditor=rtrim(@CreditSomajOcaz)+rtrim(@AnActiv)
				set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% - ocazionali'
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSomajOcaz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End
			set @ContDebitor=rtrim(@DebitSomajBolnavi)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditSomajBolnavi)+rtrim(@AnActiv)
			set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% - bolnavi'
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSomajBoln, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
--			Asigurari de sanatate individual
			set @ContDebitor=rtrim(@DebitCassActivi)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditCassActivi)+rtrim(@AnActiv)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCassActivi, @NumarDoc, 
			'Asigurari sanatate din net - activi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
--			nu s-a mai preluat partea pt. asigurari de sanatate pt. salariati bolnavi - nu suporta de angajat ci din alte surse (angajator si fonduri)
			if @AtribContDebitCassOcazO<>1
			Begin
				set @ContDebitor=rtrim(@DebitCassOcazO)+rtrim(@AnActivCAS)
				set @ContCreditor=rtrim(@CreditCassOcazP)+rtrim(@AnActiv)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCassOcazO, @NumarDoc, 
				'Asigurari sanatate din net - ocaz.', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End
			if @AtribContDebitCassOcazP<>1
			Begin
				set @ContDebitor=rtrim(@DebitCassOcazP)+rtrim(@AnActivCAS)
				set @ContCreditor=rtrim(@CreditCassOcazP)+rtrim(@AnActiv)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCassOcazP, @NumarDoc, 
				'Asigurari sanatate din net - ocaz.', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End	
			set @ContDebitor=rtrim(@DebitCassFaambp)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditCassFaambp)+rtrim(@AnActiv)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCassFaambp, @NumarDoc, 
			'Total A.S. FAAMBP - ', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
--			Impozit
			if @AnPLImpozit=0
			begin
				set @ContDebitor=rtrim(@DebitImpozitActivi)+rtrim(@AnActiv)
				set @ContCreditor=rtrim(@CreditImpozitActivi)+rtrim(@AnActivImp)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMImpozitActivi, @NumarDoc, 
				'Impozit personal permanenti - activi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
				set @ContDebitor=rtrim(@DebitImpozitBolnavi)+rtrim(@AnActiv)
				set @ContCreditor=rtrim(@CreditImpozitBolnavi)+rtrim(@AnActivImp)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMImpozitBoln, @NumarDoc, 
				'Impozit personal permanenti - bolnavi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
				set @ContDebitor=rtrim(@DebitImpozitIpotetic)+rtrim(@AnActiv)
				set @ContCreditor=rtrim(@CreditImpozitIpotetic)+rtrim(@AnActivImp)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMImpozitIpotetic, @NumarDoc, 
				'Impozit ipotetic personal permanenti - activi', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			end
			if @AtribContDebitCassOcazO<>1 and @AnPLImpozit=0
			Begin
				set @ContDebitor=rtrim(@DebitImpozitOcazO)+rtrim(@AnActiv)
				set @ContCreditor=rtrim(@CreditImpozitOcazO)+rtrim(@AnActivImp)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMImpozitOcazITO, @NumarDoc, 
				'Impozit - ocazionali', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End
			if @AtribContDebitCassOcazP<>1 and @AnPLImpozit=0
			Begin
				set @ContDebitor=rtrim(@DebitImpozitOcazP)+rtrim(@AnActiv)
				set @ContCreditor=rtrim(@CreditImpozitOcazP)+rtrim(@AnActivImp)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMImpozitOcazITP, @NumarDoc, 
				'Impozit - ocazionali', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
			End
			set @ContDebitor=rtrim(@DebitImpozitOcazO)+rtrim(@AnActivCAS)
			set @ContCreditor=rtrim(@CreditImpozitOcazP)+rtrim(@AnActiv)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMImpozitOcazRO, @NumarDoc, 
			'Impozit - ocazionali - PSR', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
--		Suma incasata
			set @ContDebitor=rtrim(@DebitSumeIncas)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditSumeIncas)+rtrim(@AnActiv)
			if @NCIndBug=1
				select @IndBug=Comanda, @DenCorM=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from config_nc where Numar_pozitie=55
			set @Explicatii='Total '+rtrim(@DenCorM)+' - '+rtrim(@LmDoc)
			if @MarcaCreditSumeIncas=0
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSumaIncas, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', @IndBug, 0, '', '', 0
			if @NCIndBug=1
			Begin
				select @IndBug=Comanda, @DenCorE=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from config_nc where Numar_pozitie=57
				set @Explicatii='Total '+rtrim(@DenCorE)+' - '+rtrim(@LmDoc)
				if @MarcaCreditSumeIncas=0
					exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCOIncasat, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @LmDoc, '', @IndBug, 0, '', '', 0
			End
			set @ContDebitor=rtrim(@CreditFaambp)+rtrim(@AnActiv)
			set @ContCreditor=rtrim(@CreditCCI)+(case when @Reva=1 then '.1' else rtrim(@AnActiv) end)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCCIFaambp, @NumarDoc, 
			'Total CCI suportat din FAAMBP - ', @Continuare output, @NrPozitie output, @LmDoc, '', '', 0, '', '', 0
		End
	End
	Set @gMarca=@Marca
	Set @gLm=@Lm
	Set @LmDoc=@Lm
End
close NCDinNet
Deallocate NCDinNet
if object_id('tempdb..#impozitIpotetic') is not null drop table #impozitIpotetic
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenNCDinNet (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec GenNCDinNet '01/01/2011', '01/31/2011', '', 1, 1
*/
