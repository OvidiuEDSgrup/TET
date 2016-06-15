/* operatie pt. generare NC pt. cheltuieli salarii */
Create procedure GenNCCheltLM
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output, @NumarDoc char(8)
As
Begin try
	/*	apelez procedura specifica care sa inlocuiasca procedura standard (Pentru inceput se foloseste la Plexus Oradea, client Angajator) */
	if exists (select * from sysobjects where name ='GenNCCheltLMSP' and type='P')
	begin
		exec GenNCCheltLMSP @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @Continuare=@Continuare output, @NrPozitie=@NrPozitie output, @NumarDoc=@NumarDoc
		return
	end

	declare @Sub char(9), @CASIndiv decimal(5,2), @SomajInd decimal(5,2), @ProcCASIndiv decimal(5,2), @ProcSomajIndiv decimal(5,2), 
	@STOUG28 int, @AcordGLTesaAcord int, @RealizGLNormaTimp int, @NuCAS_H int, @NuASS_N int, @AjDecesUnitate int, @NCTaxePLMCh int, @NCSubvSomaj int, 
	@NCIndBug int, @NCAnActiv int, @NCAnActivCtChelt int, @RepManIndCom int, @RepManIndComTL int, @NumaiPontajeAcord int, @RepAsigUnitCom int, @CheltSalComp int, 
	@Pasmatex int, @Somesana int, @NCSomesanaMures int, @cLmA19Som char(200), @LucrCuDiurneImpoz int, @CorectieDiurneImpoz varchar(2), 
	@Prodpan int, @Stoehr int, @NCConsAdmGrpMP int, 
	@Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), 
	@DenSuma char(30), @gLm char(9), @gMarca char(6), @IndBug char(20), @gActivitate varchar(10), 
	@gVenitRealizatLm decimal(10,2), 
-- variabile pt. scriere NC
	@An641TipAc int, @Cont641Dif varchar(20), @Cont641AcGl varchar(20), @Cont641AcInd varchar(20), 
	@DebitCheltPerm varchar(20), @CreditCheltPerm varchar(20), @AnLMCheltPerm int, 
	@DebitCheltOcazO varchar(20), @CreditCheltOcazO varchar(20), @AnLMCheltOcazO int, @AtribCreditOcazO int, 
	@DebitCheltOcazP varchar(20), @CreditCheltOcazP varchar(20), @AnLMCheltOcazP int, @AtribCreditOcazP int, 
	@DebitCheltAdmSal varchar(20), @DebitCheltAdmOS varchar(20), @DebitCheltAdmPremii varchar(20), 
	@DebitCheltProdSal varchar(20), @DebitCheltProdOS varchar(20), @DebitCheltProdPremii varchar(20), 
	@DebitCMUnitate1 varchar(20), @CreditCMUnitate1 varchar(20), @AnLMCMUnitate1 int, 
	@DebitCMUnitate2 varchar(20), @CreditCMUnitate2 varchar(20), @AnLMCMUnitate2 int, 
	@DebitCMFnuass1 varchar(20), @CreditCMFnuass1 varchar(20), 
	@DebitCMFnuass2 varchar(20), @CreditCMFnuass2 varchar(20), 
	@DebitCMFaambp varchar(20), @CreditCMFaambp varchar(20), 
	@DebitSumeNeimp1 varchar(20), @CreditSumeNeimp1 varchar(20), @AnLMSumeNeimp1 int, 
	@DebitSumeNeimp2 varchar(20), @CreditSumeNeimp2 varchar(20), 
	@DebitAjDeces varchar(20), @CreditAjDeces varchar(20), @DebitDiurneImpoz varchar(20), @CreditDiurneImpoz varchar(20), 
	@AnActivDeb char(10), @AnActivCre char(10), @AnActivDebCuSom char(10), @AnITMAccmSom1 char(9), @AnITMAccmSom2 char(9), 
-- variabile din fetch
	@Data datetime, @Lm char(9), @Marca char(6), @LmStatPl int, @VenitTotalBrut decimal(10), @RealizatRegie decimal(10), @RealizatAcord decimal(10), 
	@IndOreSupl1 decimal(10), @IndOreSupl2 decimal(10), @IndOreSupl3 decimal(10), @IndOreSupl4 decimal(10), 
	@IndOreSpor100 decimal(10), @IndOreNoapte decimal(10), @IndIT decimal(10), @IndObl decimal(10), @IndCO decimal(10), 
	@IndCMUnitate decimal(10), @IndIT2 decimal(10), @CMUnitate decimal(10), @IndCMFnuass decimal(10), @CMCas decimal(10), @CO decimal(10), 
	@Restituiri decimal(10), @Diminuari decimal(10), @SumaImpozabila decimal(10), @Premiu decimal(10), @Diurna decimal(10), 
	@ConsAdmin decimal(10), @SpSalarRealizat decimal(10), @SumaImpSep decimal(10), @SporVechime decimal(10), @SporNoapte decimal(10), 
	@SporSistPrg decimal(10), @SporFctSupl decimal(10), @SporSpecific decimal(10), 
	@SporCond1 decimal(10), @SporCond2 decimal(10), @SporCond3 decimal(10), @SporCond4 decimal(10), 
	@SporCond5 decimal(10), @SporCond6 decimal(10), @AjDeces decimal(10), @DiurnaImpoz decimal(12,2), @IndCMFaambp decimal(10), 
	@CategSal char(4), @GrupaM char(1), @TipSal char(1), @TipColab char(3), @Activitate varchar(10), @LmNet char(9), @VenitTotalNet decimal(10), 
	@Cas decimal(10,2), @Somaj_5 decimal(10,2), @Faambp decimal(10,2), @Itm decimal(10,2), @CassUnitate decimal(10,2), 
	@SumaNeimpozNet decimal(10), @CCI decimal(10,2), @CasCM decimal(10,2), @FondGar decimal(10,2), 
	@BazaCasCMCN decimal(10), @BazaCasCMCD decimal(10), @BazaCasCMCS decimal(10), 
	@IndCMUnitateM decimal(10), @IndCMCasM decimal(10), @CMCasM decimal(10), @CMUnitateM decimal(10), @IndCMFaambpM decimal(10), 
	@SumaNeimpozMLM decimal(10), @TipSalPontaj char(1), @AreRealizCom int, @AreRealizLmCom int, 
	@VenitRealizMarcaPas decimal(10,2), @VenitRealizatLM decimal(10,2), @SomajTehnic decimal(10), 
	@Ded_baza decimal(10), @pSomaj_1 int, @AsSanatate decimal(5,2), @Somaj_1Net decimal(10,2), 
	@SubvSomaj decimal(10,2), @ScutireSomaj decimal(10,2), @BazaCASCM decimal(10), @AvMatImpoz decimal(10,2), 
--variabile pt. totaluri pe LM Stoehr
	@TCheltLMAdmSal decimal(10,2), @TCheltLMAdmOS decimal(10,2), @TCheltLMAdmPremii decimal(10,2), 
	@TCheltLMProdSal decimal(10,2), @TCheltLMProdOS decimal(10,2), @TCheltLMProdPremii decimal(10,2),
	@TCMUnitateLMAdm decimal(10,2), @TCMUnitateLMProd decimal(10,2),
--variabile pt. totaluri pe LM
	@CheltOcazItO decimal(10,2), @CheltOcazItP decimal(10,2), @TCheltLMPerm decimal(10,2), @TCheltLMPermID decimal(10,2), @TCheltLMOcazItO decimal(10,2), @TCheltLMOcazItP decimal(10,2), 
	@TCMFnuassLM decimal(10,2), @TCMFaambpLM decimal(10,2), @TCMUnitateLM decimal(10,2), @TSumaNeimpLM decimal(10,2), 
	@TAjDecesLM decimal(10,2), @TOblProdpanLM decimal(10,2), @TDiurneImpozLM decimal(10,2), 
	@VenitNelucratMLM decimal(10,2), @CorectiiMLM decimal(10,2), @IndOreSuplMLM decimal(10,2), 
	@SporuriMLM decimal(10,2), @SumeExcPontajeAcMLM decimal(10,2), 
	@VenitLM decimal(10), @TVenitLM decimal(10,2), @TAcordLM decimal(10,2), @TRegieLM decimal(10,2), 
	@TIndOreSuplLM decimal(10,2), @TSporuriLM decimal(10,2), @TNelucratLM decimal(10,2), @TCorectiiLM decimal(10,2), 
	@TVenitRealizatLM decimal(10,2), @ValRealizataMarca decimal(10,2), @TRealizat decimal(10,2), 
	@gfetch int

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @CasIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @SomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @STOUG28=dbo.iauParLN(@dataSus,'PS','@STOUG28')
	set @AcordGLTesaAcord=dbo.iauParL('PS','ACGLOTESA')
	set @RealizGLNormaTimp=dbo.iauParL('PS','RZANORMT')
	set @NuASS_N=dbo.iauParL('PS','NUASS-N')
	set @AjDecesUnitate=dbo.iauParL('PS','AJDUNIT-R')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')
	set @RepManIndCom=dbo.iauParL('PS','NC-MI-COM')
	set @RepManIndComTL=dbo.iauParL('PS','NC-MC-TLC')
	set @NumaiPontajeAcord=dbo.iauParL('PS','NC-MC-PA')
	set @RepAsigUnitCom=dbo.iauParL('PS','NC-AU-COM')
	set @CheltSalComp=dbo.iauParL('PS','NC-CH-CMP')
	set @NCConsAdmGrpMP=dbo.iauParL('PS','NC-ADM-GP')
	select 
		@NCTaxePLMCh=max(case when Parametru='N-C-TXLMC' then Val_logica else 0 end),
		@NCSubvSomaj=max(case when Parametru='N-SUBVSJD' then Val_logica else 0 end),
		@LucrCuDiurneImpoz=max(case when Parametru='DIUIMP' then Val_logica else 0 end),
		@CorectieDiurneImpoz=max(case when Parametru='DIUIMP' then Val_alfanumerica else '' end)
	from par where parametru in ('N-C-TXLMC','N-SUBVSJD','DIUIMP')

	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @NCSomesanaMures=dbo.iauParL('PS','NC-SMURES')
	set @cLmA19Som=dbo.iauParA('PS','LOCM_A19')
	set @Prodpan=dbo.iauParL('SP','PRODPAN')
	set @Stoehr=dbo.iauParL('SP','STOEHR')

	set @An641TipAc=dbo.iauParL('PS','NC-CCH-TM')
	set @Cont641Dif=dbo.iauParA('PS','NC-CCH-TM')
	set	@Cont641AcGl=dbo.iauParA('PS','NC-CCH-AG') 
	set @Cont641AcInd=dbo.iauParA('PS','NC-CCH-AI') 
	set @DebitCheltPerm=dbo.iauParA('PS','N-C-SAL1D')
	set @AnLMCheltPerm=dbo.iauParL('PS','N-C-SAL1D')
	set @CreditCheltPerm=dbo.iauParA('PS','N-C-SAL1C')
	set @DebitCheltOcazO=dbo.iauParA('PS','N-C-SAL2D')
	set @AnLMCheltOcazO=dbo.iauParL('PS','N-C-SAL2D')
	set @CreditCheltOcazO=dbo.iauParA('PS','N-C-SAL2C')
	set @DebitCheltOcazP=dbo.iauParA('PS','N-C-SAL3D')
	set @AnLMCheltOcazP=dbo.iauParL('PS','N-C-SAL3D')
	set @CreditCheltOcazP=dbo.iauParA('PS','N-C-SAL3C')
	select @AtribCreditOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazO
	select @AtribCreditOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazP
	set @DebitCheltAdmSal=dbo.iauParA('PS','N-C-SAD')
	set @DebitCheltAdmOS=dbo.iauParA('PS','N-C-OSAD')
	set @DebitCheltAdmPremii=dbo.iauParA('PS','N-C-PRMAD')
	set @DebitCheltProdSal=dbo.iauParA('PS','N-C-SPR')
	set @DebitCheltProdOS=dbo.iauParA('PS','N-C-OSPR')
	set @DebitCheltProdPremii=dbo.iauParA('PS','N-C-PRMPR')
	set @DebitCMUnitate1=dbo.iauParA('PS','N-C-CMU1D')
	set @AnLMCMUnitate1=dbo.iauParL('PS','N-C-CMU1D')
	set @CreditCMUnitate1=dbo.iauParA('PS','N-C-CMU1C')
	set @DebitCMUnitate2=dbo.iauParA('PS','N-C-CMU2D')
	set @AnLMCMUnitate2=dbo.iauParL('PS','N-C-CMU2D')
	set @CreditCMUnitate2=dbo.iauParA('PS','N-C-CMU2C')
	set @DebitCMFnuass1=dbo.iauParA('PS','N-C-CMC1D')
	set @CreditCMFnuass1=dbo.iauParA('PS','N-C-CMC1C')
	set @DebitCMFnuass2=dbo.iauParA('PS','N-C-CMC2D')
	set @CreditCMFnuass2=dbo.iauParA('PS','N-C-CMC2C')
	set @DebitCMFaambp=dbo.iauParA('PS','N-CMFABPD')
	set @CreditCMFaambp=dbo.iauParA('PS','N-CMFABPC')
	set @DebitSumeNeimp1=dbo.iauParA('PS','N-C-NEI1D')
	set @CreditSumeNeimp1=dbo.iauParA('PS','N-C-NEI1C')
	set @AnLMSumeNeimp1=dbo.iauParL('PS','N-C-NEI1D')
	set @DebitSumeNeimp2=dbo.iauParA('PS','N-C-NEI2D')
	set @CreditSumeNeimp2=dbo.iauParA('PS','N-C-NEI2C')
	set @DebitAjDeces=dbo.iauParA('PS','N-C-AJDDB')
	set @CreditAjDeces=dbo.iauParA('PS','N-C-AJDCR')
	set @DebitDiurneImpoz=dbo.iauParA('PS','N-C-DIMDB')
	set @CreditDiurneImpoz=dbo.iauParA('PS','N-C-DIMCR')

	/*	Validare daca exista marca cu activitate necompletata. */
	if @NCAnActiv=1
	begin
		declare @marcaFaraActivitate varchar(6), @mesajEroare varchar(1000)
		select top 1 @marcaFaraActivitate=p.marca 
		from personal p
			inner join #net n on n.marca=p.marca and n.Venit_total<>0
		where nullif(activitate,'') is null

		if @marcaFaraActivitate is not null
		begin
			set @mesajEroare='Marca (' + RTrim(@marcaFaraActivitate) + ') nu are completata activitatea in macheta de salariati!'
			raiserror(@mesajEroare, 16, 1)
		end
	end

	declare CheltLM cursor for
	select b.Data, b.Loc_de_munca, b.Marca, convert(char(1),b.Loc_munca_pt_stat_de_plata), b.VENIT_TOTAL, 
	b.Realizat__regie, b.Realizat_acord, b.Indemnizatie_ore_supl_1, b.Indemnizatie_ore_supl_2, b.Indemnizatie_ore_supl_3, b.Indemnizatie_ore_supl_4, 
	b.Indemnizatie_ore_spor_100, b.Ind_ore_de_noapte, b.Ind_intrerupere_tehnologica, b.Ind_obligatii_cetatenesti, b.Ind_concediu_de_odihna, 
	b.Ind_c_medical_unitate, b.Ind_invoiri, b.CMunitate, b.Ind_c_medical_CAS, b.CMCAS, b.CO, b.Restituiri, 
	b.Diminuari, b.Suma_impozabila, b.Premiu, b.Diurna, b.Cons_admin, b.Sp_salar_realizat, b.Suma_imp_separat, 
	b.Spor_vechime, b.Spor_de_noapte, b.Spor_sistematic_peste_program, b.Spor_de_functie_suplimentara, b.Spor_specific, 
	b.Spor_cond_1, b.Spor_cond_2, b.Spor_cond_3, b.Spor_cond_4, b.Spor_cond_5, b.Spor_cond_6, b.Compensatie, b.Spor_cond_9, 
	i.categoria_salarizare, i.grupa_de_munca, i.tip_salarizare, i.Tip_colab, 
	(case when @Somesana=1 or @NCAnActiv=1 then isnull(p.Activitate,'') else '' end) as Activitate, 
	n.Loc_de_munca, isnull(n.Venit_total,0), isnull(n.Cas,0), isnull(n.Somaj_5,0), isnull(n.Fond_de_risc_1,0), isnull(n.Camera_de_munca_1,0), 
	isnull(n.Asig_sanatate_pl_unitate+n1.Asig_sanatate_din_impozit,0), 
	isnull(n.Suma_neimpozabila,0), isnull(n.Ded_suplim,0), isnull(n1.Cas,0), isnull(n1.Somaj_5,0), isnull(n1.Baza_cas_cond_norm,0), isnull(n1.Baza_cas_cond_deoseb,0), isnull(n1.Baza_cas_cond_spec,0), 
	isnull(bm.ind_c_medical_unitate,0), isnull(bm.ind_c_medical_cas,0), isnull(bm.CMCAS,0), isnull(bm.CMunitate,0), isnull(bm.spor_cond_9,0), isnull(c.suma_corectie,0), 
	isnull((select max(p.tip_salarizare) from pontaj p where (@Pasmatex=1 or @RepManIndCom=1 or @RepManIndComTL=1) and p.data between @dataJos and @dataSus 
		and p.marca=b.marca and p.loc_de_munca=b.loc_de_munca),''), 
	isnull((select count(1) from realcom r where r.data between @dataJos and @dataSus and r.marca=b.marca),0), 
	isnull((select count(1) from realcom r where r.data between @dataJos and @dataSus and r.marca=b.marca and r.loc_de_munca=b.loc_de_munca and left(r.numar_document,3)<>'DLG'),0), 
	isnull((select sum(round(Cantitate*Tarif_unitar,2)) from realcom r where r.data between @dataJos and @dataSus and r.marca=b.marca and r.loc_de_munca=b.loc_de_munca),0), 
	isnull((select sum(round((case when @RealizGLNormaTimp=1 then r.Cantitate*r.Norma_de_timp*(r1.Valoare_manopera/r1.Ore_realizate_in_acord) else r.Cantitate*r.Tarif_unitar end),2))
		from realcom r
			left outer join reallmun r1 on r1.Data=@dataSus and r1.Loc_de_munca=r.Loc_de_munca
			left outer join brut b1 on b1.Data=@dataSus and b1.Marca=r.Marca and b1.Loc_de_munca=r.Loc_de_munca
		where r.Data between @dataJos and @dataSus and r.Marca='' and r.Loc_de_munca=b.Loc_de_munca),0), 
	(case when @STOUG28=1 then bm.Ind_invoiri else 0 end) as Somaj_tehnic, n.Ded_baza, p.Somaj_1, p.As_sanatate, n.Somaj_1, n.Chelt_prof, isnull(s.Scutire_art80,0)+isnull(s.Scutire_art85,0),
	isnull(di.Suma_corectie,0) as DiurneImpoz, isnull(nullif(ai.Suma_neta,0),isnull(ai.Suma_corectie,0)) as AvMatImpoz
	from #brut b
		left outer join personal p on p.marca=b.marca
		left outer join infopers ip on ip.marca=b.marca
		left outer join #net n on n.data=b.data and n.marca=b.marca
		left outer join #net n1 on n1.data=dbo.bom(b.data) and n1.marca=b.marca
		left outer join istpers i on i.data=b.data and i.marca=b.marca
		left outer join corectii c on c.data=b.data and c.marca=b.marca and c.loc_de_munca=b.loc_de_munca and c.tip_corectie_venit='N-'
		left outer join #brutMarca bm on bm.data=b.data and bm.marca=b.marca
		left outer join dbo.fScutiriSomaj (@dataJos, @dataSus, '', 'ZZZ', '', 'ZZZ') s on s.Data=b.Data and s.Marca=b.Marca
		left outer join fSumeCorectie (@dataJos, @dataSus, @CorectieDiurneImpoz, '', '', 1) di on @LucrCuDiurneImpoz=1 and di.Data=b.data and di.Marca=b.Marca and di.Loc_de_munca=b.Loc_de_munca
		left outer join fSumeCorectie (@dataJos, @dataSus, 'AI', '', '', 1) ai on ai.Data=b.data and ai.Marca=b.Marca and ai.Loc_de_munca=b.Loc_de_munca
	where b.data=@dataSus and (@NCSomesanaMures=0 or b.loc_de_munca between '40' and '40'+'ZZZ') 
		and (@pMarca='' or b.marca=@pMarca) and b.Data>=p.Data_angajarii_in_unitate
	order by isnull(p.Activitate,''), b.loc_de_munca, b.Marca

	open CheltLM
	fetch next from CheltLM into @Data, @Lm, @Marca, @LmStatPl, @VenitTotalBrut, @RealizatRegie, @RealizatAcord, 
		@IndOreSupl1, @IndOreSupl2, @IndOreSupl3, @IndOreSupl4, @IndOreSpor100, @IndOreNoapte, @IndIT, @IndObl, @IndCO, @IndCMUnitate, @IndIT2, @CMUnitate, @IndCMFnuass, @CMCAS, 
		@CO, @Restituiri, @Diminuari, @SumaImpozabila, @Premiu, @Diurna, @ConsAdmin, @SpSalarRealizat, @SumaImpSep, 
		@SporVechime, @SporNoapte, @SporSistPrg, @SporFctSupl, @SporSpecific, @SporCond1, @SporCond2, @SporCond3, @SporCond4, @SporCond5, @SporCond6, 
		@AjDeces, @IndCMFaambp, @CategSal, @GrupaM, @TipSal, @TipColab, @Activitate, 
		@LmNet, @VenitTotalNet, @Cas, @Somaj_5, @Faambp, @Itm, @CassUnitate, @SumaNeimpozNet, @CCI, @CasCM, @FondGar, 
		@BazaCasCMCN, @BazaCasCMCD, @BazaCasCMCS, @IndCMUnitateM, @IndCMCasM, @CMCasM, @CMUnitateM, @IndCMFaambpM, 
		@SumaNeimpozMLM, @TipSalPontaj, @AreRealizCom, @AreRealizLmCom, @VenitRealizMarcaPas, @VenitRealizatLM, @SomajTehnic, 
		@Ded_baza, @pSomaj_1, @AsSanatate, @Somaj_1Net , @SubvSomaj, @ScutireSomaj, @DiurnaImpoz, @AvMatImpoz
	select @TRealizat=0
	select @TRealizat=sum(cantitate*tarif_unitar) from realcom where @Pasmatex=1 and data between @dataJos and @dataSus
	set @gfetch=@@fetch_status
	set @gMarca=@Marca
	set @gLm=@Lm
	set @gActivitate=@Activitate
	set @gVenitRealizatLm=@VenitRealizatLm
	While @gfetch = 0 
	Begin
		select @TCheltLMAdmSal=0, @TCheltLMAdmOS=0, @TCheltLMAdmPremii=0, @TCheltLMProdSal=0, 
			@TCheltLMProdOS=0, @TCheltLMProdPremii=0, @TCMUnitateLMAdm=0, @TCMUnitateLMProd=0, 
			@TCheltLMPerm=0, @TCheltLMPermID=0, @TCheltLMOcazItO=0, @TCheltLMOcazItP=0, 
			@TCMFnuassLM=0, @TCMFaambpLM=0, @TCMUnitateLM=0, @TSumaNeimpLM=0, 
			@TAjDecesLM=0, @TOblProdpanLM=0, @TDiurneImpozLM=0, @VenitLM=0, @TVenitLM=0, @TVenitRealizatLM=0
		select @TAcordLM=0, @TRegieLM=0, @TIndOreSuplLM=0, @TSporuriLM=0, @TNelucratLM=0, @TCorectiiLM=0
			where @CheltSalComp=1
		while @Lm = @gLm and @gfetch = 0
		Begin
--	calcul sume pe locuri de munca
			select @VenitNelucratMLM=@IndObl+@IndCO+@IndIT+@IndIT2, @CorectiiMLM=@CO+@Restituiri-@Diminuari+@SumaImpozabila+@Diurna+@ConsAdmin+@SumaImpSep, 
				@IndOreSuplMLM=@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4+@IndOreSpor100+@IndOreNoapte, 
				@SporuriMLM=@SporVechime+@SporSpecific+@SporNoapte+@SporSistPrg+@SporFctSupl+
				@SporCond1+@SporCond2+@SporCond3+@SporCond4+@SporCond5+@SporCond6+@Premiu+@SpSalarRealizat
			set @SumeExcPontajeAcMLM=@RealizatRegie+(case when @RealizatAcord=0 then @IndOreSuplMLM+@SporuriMLM 
				else (case when @RealizatRegie=0 and @RealizatAcord<>0 then 0 else (@IndOreSuplMLM+@SporuriMLM)*@RealizatRegie/(@RealizatRegie+@RealizatAcord) end) end)
			set @AnActivDeb=(case when @NCAnActiv=1 then '.'+rtrim(@Activitate) else '' end)
			set @AnActivCre=(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(@Activitate) else '' end)

			if @LmNet=@Lm
				set @TSumaNeimpLm=@TSumaNeimpLm+@SumaNeimpozNet

			set @TCheltLMPerm=@TCheltLMPerm+(case when @GrupaM in ('O','P') and not(@Somesana=1 and (@Activitate='1' or @Lm='1291')) then 0 
				else (case when @Somesana=1 then (case when @Activitate='31' then @RealizatRegie+@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4 else 0 end) 
					else @VenitTotalBrut-(@IndCMUnitate+@CMUnitate+@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz)-(case when @Prodpan=1 then @IndObl else 0 end)-@DiurnaImpoz end) end)
			set @TCheltLMPerm=@TCheltLMPerm-(case when @GrupaM in ('O','P') or @NuASS_N=1 then 0 else @SumaNeimpozMLM end)
			set @TCheltLMPermID=@TCheltLMPermID+(case when @GrupaM in ('O','P') then 0 
				else (case when @Somesana=1 then @VenitTotalBrut-(@IndCMUnitate+@IndCMFnuass+@IndCMFaambp)-
				(case when @Activitate='31' then @RealizatRegie+@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4 else 0 end) else 0 end) end)
			set @TCheltLMPermID=@TCheltLMPermID-(case when @GrupaM in ('O','P') or @NuASS_N=1 then 0 else 
				(case when @Somesana=1 and @Activitate='31' then @SumaNeimpozMLM else 0 end) end)
		
			set @CheltOcazItO=(case when (@GrupaM='O' or @GrupaM='P' and @TipColab in ('AS5','AS2') and @NCConsAdmGrpMP=0) 
				and not(@Somesana=1 and (@Activitate='1' or @Lm='1291')) then @VenitTotalBrut-(@IndCMUnitate+@CMUnitate+@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz) else 0 end)
			set @TCheltLMOcazItO=@TCheltLMOcazItO+@CheltOcazItO
			set @CheltOcazItP=(case when @GrupaM='P' and (not(@TipColab in ('AS5','AS2')) or @NCConsAdmGrpMP=1)
				and not(@Somesana=1 and (@Activitate='1' or @Lm='1291')) then @VenitTotalBrut-(@IndCMUnitate+@CMUnitate+@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz) else 0 end)
			set @TCheltLMOcazItP=@TCheltLMOcazItP+@CheltOcazItP
			set @TCMUnitateLM=@TCMUnitateLM+@IndCMUnitate+@CMUnitate
			if @Stoehr=1
			Begin
				if @TipSal in ('1','2')
				Begin
					set @TCheltLMAdmSal=@TCheltLMAdmSal+@VenitTotalBrut-(@IndCMUnitate+@CMUnitate+@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz)
						-(@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4)-(@Premiu+@SumaImpozabila)
					set @TCheltLMAdmOS=@TCheltLMAdmOS+@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4
					set @TCheltLMAdmPremii=@TCheltLMAdmPremii+@Premiu+@SumaImpozabila
					set	@TCMUnitateLMAdm=@TCMUnitateLMAdm+@IndCMUnitate+@CMUnitate
				End
				if not(@TipSal in ('1','2'))
				Begin
					set @TCheltLMProdSal=@TCheltLMProdSal+@VenitTotalBrut-(@IndCMUnitate+@CMUnitate+@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz)
						-(@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4)-(@Premiu+@SumaImpozabila)
					set @TCheltLMProdOS=@TCheltLMProdOS+@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4
					set @TCheltLMProdPremii=@TCheltLMProdPremii+@Premiu+@SumaImpozabila
					set @TCMUnitateLMProd=@TCMUnitateLMProd+@IndCMUnitate+@CMUnitate 
				End
			End
			set @TCMFnuassLM=@TCMFnuassLM+@IndCMFnuass+@CMCas
			set @TCMFaambpLM=@TCMFaambpLM+@IndCMFaambp
			if not(@AreRealizLmCom<>0) and (@AcordGLTesaAcord=1 or @TipSalPontaj<>'2')
			Begin
				set @TVenitLM=@TVenitLM+@VenitTotalBrut-(@IndCMUnitate+@CMUnitate+@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz+@AvMatImpoz)
					-(case when @Prodpan=1 then @IndObl else 0 end)
					-(case when @RepManIndComTL=1 then @VenitNelucratMLM+@CorectiiMLM else 0 end)
					-(case when @NumaiPontajeAcord=1 then @SumeExcPontajeAcMLM else 0 end)
			End
			select @TAcordLM=@TAcordLM+@RealizatAcord, @TRegieLM=@TRegieLM+@RealizatRegie, 
				@TIndOreSuplLM=@TIndOreSuplLM+@IndOreSuplMLM, @TSporuriLM=@TSporuriLM+@SporuriMLM, 
				@TNelucratLM=@TNelucratLM+@VenitNelucratMLM, @TCorectiiLM=@TCorectiiLM+@CorectiiMLM
			where @CheltSalComp=1
			set @TAjDecesLM=@TAjDecesLM+@AjDeces
			set @TOblProdpanLM=@TOblProdpanLM+@IndObl
			set @TDiurneImpozLM=@TDiurneImpozLM+@DiurnaImpoz
			set @ProcCASIndiv=(case when @GrupaM<>'O' then @CasIndiv else 0 end)
			set @ProcSomajIndiv=(case when @pSomaj_1=1 then @SomajInd else 0 end)
			set @BazaCasCM=@BazaCasCMCN+@BazaCasCMCD+@BazaCasCMCS
			exec scriuCASBrut
				@Data, @Marca, @Lm, @LmStatPl, @VenitTotalBrut, @IndCMUnitate, @CMUnitate, @IndCMFnuass, @CMCas, @IndCMFaambp, 
				@VenitTotalNet, @Cas, @Somaj_5, @Faambp, @ITM, @CassUnitate, @CCI, @CASCM, @FondGar, 
				@IndCMUnitateM, @CMunitateM, @IndCMCasM, @CMCasM, @IndCMFaambpM, 0, 0, @Ded_baza, 
				@ProcCASIndiv, @pSomaj_1, @AsSanatate, @BazaCASCM, @Somaj_1Net, @SubvSomaj, @ScutireSomaj, @NCTaxePLMCh, @NCSubvSomaj
--	procedura pt. cheltuieli pe lm si com
			if @Pasmatex=1
				exec GenNCCheltLMCom @dataJos, @dataSus, @pMarca, @Marca, @Lm, @Continuare output, @NrPozitie output, @Activitate, 
				@TCheltLMPerm output, @TCheltLMOcazItO output, @TCheltLMOcazItP output, @TCMUnitateLM output, 
				@TAcordLM, @TRegieLM, @TIndOreSuplLM, @TSporuriLM, @TNelucratLM, @TCorectiiLM, 
				@TVenitLM, @TVenitRealizatLM, @ValRealizataMarca output, @NumarDoc
			select @ValRealizataMarca=@VenitRealizMarcaPas where @Pasmatex=1 and @TipSalPontaj='4'
--	procedura pt. generare dif.	regie+acord-manopera (Specific Pasmatex)
			if @Pasmatex=1 and @TipSalPontaj='4'
				exec GenNCDifManopera @dataJos, @dataSus, @Lm, @NumarDoc, @Sub, @DebitCheltPerm, @CreditCheltPerm, @AnLMCheltPerm, 
				@RealizatRegie, @RealizatAcord, @ValRealizataMarca, @TRealizat, @Continuare output, @NrPozitie output, @TCheltLMPerm output
			if @Continuare=1 and @AtribCreditOcazO=1 and @AreRealizLmCom=0
			Begin
				set @ContDebitor=rtrim(@DebitCheltOcazO)+rtrim(@AnActivDeb)
				set @ContCreditor=rtrim(@CreditCheltOcazO)+rtrim(@AnActivCre)			
				set @Explicatii='Chelt. sal. ocazionali - marca '+rtrim(@Marca)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @CheltOcazItO, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltOcazO, @Marca, '', 0
			End	
			if @Continuare=1 and @AtribCreditOcazP=1 and @AreRealizLmCom=0
			Begin
				set @ContDebitor=rtrim(@DebitCheltOcazP)+rtrim(@AnActivDeb)
				set @ContCreditor=rtrim(@CreditCheltOcazP)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. ocazionali - marca '+rtrim(@Marca)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @CheltOcazItP, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltOcazP, @Marca, '', 0
			End	
			set @gVenitRealizatLm=@VenitRealizatLm
			fetch next from CheltLM into @Data, @Lm, @Marca, @LmStatPl, @VenitTotalBrut, @RealizatRegie, @RealizatAcord, 
				@IndOreSupl1, @IndOreSupl2, @IndOreSupl3, @IndOreSupl4, @IndOreSpor100, @IndOreNoapte, @IndIT, @IndObl, @IndCO, 
				@IndCMUnitate, @IndIT2, @CMUnitate, @IndCMFnuass, @CMCAS, @CO, @Restituiri, @Diminuari, @SumaImpozabila, @Premiu, @Diurna, 
				@ConsAdmin, @SpSalarRealizat, @SumaImpSep, @SporVechime, @SporNoapte, @SporSistPrg, @SporFctSupl, @SporSpecific, 
				@SporCond1, @SporCond2, @SporCond3, @SporCond4, @SporCond5, @SporCond6, @AjDeces, @IndCMFaambp, 
				@CategSal, @GrupaM, @TipSal, @TipColab, @Activitate, 
				@LmNet, @VenitTotalNet, @Cas, @Somaj_5, @Faambp, @Itm, @CassUnitate, @SumaNeimpozNet, @CCI, @CasCM, @FondGar, 
				@BazaCasCMCN, @BazaCasCMCD, @BazaCasCMCS, @IndCMUnitateM, @IndCMCasM, @CMCasM, @CMUnitateM, @IndCMFaambpM, 
				@SumaNeimpozMLM, @TipSalPontaj, @AreRealizCom, @AreRealizLmCom, @VenitRealizMarcaPas, @VenitRealizatLM, @SomajTehnic, 
				@Ded_baza, @pSomaj_1, @AsSanatate, @Somaj_1Net, @SubvSomaj, @ScutireSomaj, @DiurnaImpoz, @AvMatImpoz
			set @gfetch=@@fetch_status
		End
		set @TVenitRealizatLM=@gVenitRealizatLm
--	procedura pt. asigurari pe lm si com
		if @Pasmatex=0 
			exec GenNCCheltLMCom @dataJos, @dataSus, @pMarca, @gMarca, @gLm, @Continuare output, @NrPozitie output, @gActivitate, 
				@TCheltLMPerm output, @TCheltLMOcazItO output, @TCheltLMOcazItP output, @TCMUnitateLM output, 
				@TAcordLM, @TRegieLM, @TIndOreSuplLM, @TSporuriLM, @TNelucratLM, @TCorectiiLM, 
				@TVenitLM, @TVenitRealizatLM, @ValRealizataMarca output, @NumarDoc
		set	@AnActivDebCuSom=(case when @Somesana=1 or @NCAnActiv=1 
			then '.'+(case when @Somesana=1 and (@gActivitate='31' or @gActivitate='32') and @NCSomesanaMures=0 then left(rtrim(@gActivitate),1) 
				else rtrim(@gActivitate) end)
			+(case when @Somesana=1 and (@gActivitate='9' or @gActivitate='10') and charindex(@gLm,@cLmA19Som)<>0 then '.19' else '' end) else '' end)
		set @AnITMAccmSom1=(case when @Somesana=1 and @NCSomesanaMures=0 then (case when @gActivitate='31' then '.1' when @gActivitate='32' then '.2' else '' end) else '' end)
		set @AnITMAccmSom2=(case when @Somesana=1 and @NCSomesanaMures=0 then (case when (@gActivitate='31' or @gActivitate='32') then '.2' else '' end) else '' end)
--	generare note contabile pentru cheltuieli (pe tipuri)
		if @Continuare=1
		Begin
			if @Stoehr=0
			Begin
				set @ContDebitor=(case when @An641TipAc=1 then rtrim(@Cont641Dif) else rtrim(@DebitCheltPerm)+rtrim(@AnActivDebCuSom) end)
				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCheltLmPerm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', @AnITMAccmSom1, 0

				set @ContDebitor=(case when @An641TipAc=1 then rtrim(@Cont641Dif) 
					else rtrim(@DebitCheltPerm)+(case when @Somesana=1 or @NCAnActiv=1 
					then '.'+(case when @Somesana=1 and (@gActivitate='31' or @gActivitate='32') and @NCSomesanaMures=0 then left(rtrim(@gActivitate),1) else rtrim(@gActivitate) end)
					+(case when @Somesana=1 and (@gActivitate='9' or @gActivitate='10') and charindex(@gLm,@cLmA19Som)<>0 then '.19' else '' end)
					else '' end) end)
				set @Explicatii='Chelt. sal. permanenti - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @CreditCheltPerm, @TCheltLmPermID, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', @AnITMAccmSom2, 0
				if @AtribCreditOcazO<>1
				Begin
					set @ContDebitor=rtrim(@DebitCheltOcazO)+rtrim(@AnActivDeb)
					set @ContCreditor=rtrim(@CreditCheltOcazO)+rtrim(@AnActivCre)			
					set @Explicatii='Chelt. sal. ocazionali - '+rtrim(@gLm)
					exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCheltLmOcazItO, @NumarDoc, 
						@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltOcazO, '', '', 0
				End	

				if @AtribCreditOcazP<>1
				Begin
					set @ContDebitor=rtrim(@DebitCheltOcazP)+rtrim(@AnActivDeb)
					set @ContCreditor=rtrim(@CreditCheltOcazP)+rtrim(@AnActivCre)			
					set @Explicatii='Chelt. sal. ocazionali - '+rtrim(@gLm)
					exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCheltLmOcazItP, @NumarDoc, 
						@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltOcazP, '', '', 0
				End
			End	
			else
			Begin
				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti ADM - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltAdmSal, @ContCreditor, @TCheltLmAdmSal, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', '', 0

				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti OS ADM - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltAdmOS, @ContCreditor, @TCheltLmAdmOS, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', '', 0

				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti Premii ADM - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltAdmPremii, @ContCreditor, @TCheltLmAdmPremii, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', '', 0

				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti PROD - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltProdSal, @ContCreditor, @TCheltLmProdSal, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', '', 0

				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti OS PROD - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltProdOS, @ContCreditor, @TCheltLmProdOS, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', '', 0

				set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
				set @Explicatii='Chelt. sal. permanenti Premii PROD - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltProdPremii, @ContCreditor, @TCheltLmProdPremii, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCheltPerm, '', '', 0
			End
--	concedii medicale		
			if @Stoehr=0
			Begin
				set @ContDebitor=rtrim(@DebitCMUnitate1)+rtrim(@AnActivDebCuSom)
				set @ContCreditor=rtrim(@CreditCMUnitate1)+rtrim(@AnActivCre)
				set @Explicatii='CM unitate - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCMUnitateLm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCMUnitate1, '', @AnITMAccmSom2, 0
			End
			else
			Begin
				set @ContCreditor=rtrim(@CreditCMUnitate1)+rtrim(@AnActivCre)
				set @Explicatii='CM unitate ADM - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltAdmSal, @ContCreditor, @TCMUnitateLmAdm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCMUnitate1, '', '', 0

				set @ContCreditor=rtrim(@CreditCMUnitate1)+rtrim(@AnActivCre)
				set @Explicatii='CM unitate PROD - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCheltProdSal, @ContCreditor, @TCMUnitateLmProd, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCMUnitate1, '', '', 0
			End
			if @DebitCMUnitate2<>''
			Begin
				set @ContDebitor=rtrim(@DebitCMUnitate2)+rtrim(@AnActivCre)
				set @ContCreditor=rtrim(@CreditCMUnitate2)+rtrim(@AnActivCre)
				set @Explicatii='CM unitate - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCMUnitateLm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCMUnitate1, '', @AnITMAccmSom2, 0
			End	
			set @ContDebitor=rtrim(@DebitCMFnuass1)+rtrim(@AnActivCre)
			set @ContCreditor=rtrim(@CreditCMFnuass1)+rtrim(@AnActivCre)
			set @Explicatii='CM FNUASS - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCMFnuassLm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCMUnitate1, '', '', 0
			if @DebitCMFnuass2<>''
			Begin
				set @ContDebitor=rtrim(@DebitCMFnuass2)+rtrim(@AnActivCre)
				set @ContCreditor=rtrim(@CreditCMFnuass2)+rtrim(@AnActivCre)
				set @Explicatii='CM FNUASS - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCMFnuassLm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0
			End	
			set @ContDebitor=rtrim(@DebitCMFaambp)+rtrim(@AnActivCre)
			set @ContCreditor=rtrim(@CreditCMFaambp)+rtrim(@AnActivCre)
			set @Explicatii='CM FAAMBP - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCMFaambpLm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0
			if @DebitCMFnuass2<>''
			Begin
				set @ContDebitor=rtrim(@DebitCMFnuass2)+rtrim(@AnActivCre)
				set @ContCreditor=rtrim(@CreditCMFnuass2)+rtrim(@AnActivCre)
				set @Explicatii='CM FAAMBP - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TCMFaambpLm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0
			End	
--	sume neimpozabile
			set @ContDebitor=rtrim(@DebitSumeNeimp1)+rtrim(@AnActivDeb)
			set @ContCreditor=rtrim(@CreditSumeNeimp1)+rtrim(@AnActivCre)
			set @Explicatii='Sume neimpozabile - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TSumaNeimpLm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMSumeNeimp1, '', '', 0
			exec scriuNCsalarii @dataSus, @DebitSumeNeimp2, @CreditSumeNeimp2, @TSumaNeimpLm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMSumeNeimp1, '', '', 0
			if @Prodpan=1
			Begin
				set @ContDebitor=rtrim(@DebitSumeNeimp1)+rtrim(@AnActivDeb)
				set @ContCreditor=rtrim(@CreditSumeNeimp1)+rtrim(@AnActivCre)
				set @Explicatii='Obligatii cetatenesti - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TOblProdpanLM, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMSumeNeimp1, '', '', 0
				exec scriuNCsalarii @dataSus, @DebitSumeNeimp2, @CreditSumeNeimp2, @TOblProdpanLM, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMSumeNeimp1, '', '', 0
			End
--	ajutor deces
			set @ContDebitor=rtrim(@DebitAjDeces)+rtrim(@AnActivCre)
			set @ContCreditor=rtrim(@CreditAjDeces)+rtrim(@AnActivCre)
			set @Explicatii='Ajutor de deces - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TAjDecesLm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0
			if @AjDecesUnitate=0
			Begin
				set @Explicatii='Ajutor de deces - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitCMFnuass2, @CreditCMFnuass2, @TAjDecesLm, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0
			End
			set @ContDebitor=rtrim(@DebitCheltPerm)+rtrim(@AnActivDeb)
			if @CheltSalComp=1 and @TCMUnitateLm<>0
				exec scriuCheltComp @Data, @gLm, '', @ContDebitor, 'Concedii medicale unitate', @TCMUnitateLm
--	diurne impozabile contate separat (cele care se introduc in salarii doar pentru retinerea contributiilor)
			set @ContDebitor=rtrim(@DebitDiurneImpoz)+rtrim(@AnActivDeb)
			set @ContCreditor=rtrim(@CreditDiurneImpoz)+rtrim(@AnActivCre)
			set @Explicatii='Diurne impozabile - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @TDiurneImpozLM, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0

		End

		set @gMarca=@Marca
		set @gLm=@Lm
		set @gActivitate=@Activitate
	End
	close CheltLM
	Deallocate CheltLM

	/*	apelez procedura specifica care sa modifice continutul tabelei #docPozncon (Pentru inceput se foloseste la Plexus Oradea, client Angajator) */
	if exists (select * from sysobjects where name ='GenNCCheltLMSP1' and type='P')
	begin
		exec GenNCCheltLMSP1 @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @Continuare=@Continuare output, @NrPozitie=@NrPozitie output, @NumarDoc=@NumarDoc
		return
	end
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenNCCheltLM (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
/*
	exec GenNCCheltLM '02/01/2011', '02/28/2011', '', 1, 309014
*/
