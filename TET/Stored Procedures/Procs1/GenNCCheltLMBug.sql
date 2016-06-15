/* operatie pt. generare NC pt. cheltuieli pe locuri de munca (bugetari) */
Create procedure GenNCCheltLMBug
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output, @NumarDoc char(8)
As
Begin try
	declare @userASiS char(10), @Sub char(9), @CASIndiv decimal(5,2), @SomajInd decimal(5,2), @ProcCASIndiv decimal(5,2), @ProcSomajIndiv decimal(5,2), @LmStatSal int, 
	@SpSpecSalBaza int, @IndCondSalBaza int, @Sp1SalBaza int, @DenSuma char(30), @NCIndBug int, @NCTaxePLMCh int, @NCSubvSomaj int, 
	@CreditCheltOcazO varchar(20), @AtribCreditCheltOcazO int, @CreditCheltOcazP varchar(20), @AtribCreditCheltOcazP int, 
	@AnLMDebitChelt int, @AnLMDebitCheltOcazO int, @AnLMDebitCheltOcazP int, @AnLMDebitCMUnitate1 int, 
	@DebitCMUnitate2 varchar(20), @CreditCMUnitate2 varchar(20), @DebitCMCas2 varchar(20), @CreditCMCas2 varchar(20), 
	@Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), 
	@gMarca char(6), 
--	variabile din fetch
	@Data datetime, @Marca char(6), @Lm char(9), @LmStatPl int, @VenitTotalBrut decimal(10), 
	@SalBazaRealizat decimal(10), @IndOreSupl decimal(10), @IndCO decimal(10), @IndCMUnitate decimal(10), 
	@CMunitate decimal(10), @IndCMCAS decimal(10), @CMCAS decimal(10), @CorD decimal(10), @CorZ decimal(10), 
	@Restituiri decimal(10), @Diminuari decimal(10), @SumaImpozabila decimal(10), @Premiu decimal(10), @Premiu2 decimal(10), 
	@Diurna decimal(10), @Diurna2 decimal(10), @ConsAdmin decimal(10), @SpSalarRealizat decimal(10), @SumaImpSeparat decimal(10),
	@IndCond decimal(10), @SporSpecific decimal(10), @SporVechime decimal(10), 
	@SporDeNoapte decimal(10), @SporSistPrg decimal(10), @SporFunctieSupl decimal(10), 
	@SporCond1 decimal(10), @SporCond2 decimal(10), @SporCond3 decimal(10), @SporCond4 decimal(10), 
	@SporCond5 decimal(10), @SporCond6 decimal(10), @SporCond7 decimal(10), @SporCond8 decimal(10), @AlteSporuri decimal(10), 
	@AjDeces decimal(10), @AjutoareMat decimal(10), @IndCMFaambp decimal(10), @Grupa_de_munca char(1), @LmNet char(9), 
	@VenitTotalNet decimal(10), @Cas decimal(8,2), @Somaj_5 decimal(8,2), @Faambp decimal(8,2), @ComisionITM decimal(8,2), @CassUnitate decimal(8,2), 
	@SumaNeimpozabila decimal(10), @CCI decimal(8,2), @CasCM decimal(8,2), @FondGarantare decimal(8,2), 
	@IndCMUnitateMarca decimal(10), @IndCMCasMarca decimal(10), @CMCASMarca decimal(10), @CMunitateMarca decimal(10), 
	@IndCMFaambpMarca decimal(10), @DedPers decimal(10), @SomajPers int, @AsSanatatePers decimal(5,2), 
	@BazaCasCM decimal(10), @Somaj_1 decimal(10), @SubvSomaj decimal(10), @ScutireSomaj decimal(10), 
	@Sortare_lm varchar(20), @IndBug char(20), @gLm char(9), 
--	variabile pt. totaluri pe LM
	@LMSalRealiz decimal(10), @LMSalRealizOcazO decimal(10), @LMSalRealizOcazP decimal(10), @LMCMUnitate decimal(10), @LMIndOreSupl decimal(10), 
	@LMIndCO decimal(10), @LMIndCond decimal(10), @LMSporSpec decimal(10), @LMSporVech decimal(10), 
	@LMSporDeNoapte decimal(10), @LMSporSistPrg decimal(10), @LMSporFunctieSupl decimal(10), @LMSporCond1 decimal(10), 
	@LMSporCond2 decimal(10), @LMSporCond3 decimal(10), @LMSporCond4 decimal(10), @LMSporCond5 decimal(10), 
	@LMSporCond6 decimal(10), @LMSporCond7 decimal(10), @LMSporCond8 decimal(10), 
	@LMAlteSporuri decimal(10), @LMCMFnuass decimal(10), @LMCMFaambp decimal(10), @LMCorD decimal(10), @LMCorZ decimal(10), 
	@LMCorF decimal(10), @LMCorG decimal(10), @LMCorH decimal(10), @LMCorI decimal(10), @LMCorX decimal(10), 
	@LMCorJ decimal(10), @LMCorY decimal(10), @LMCorK decimal(10), @LMCorL decimal(10), @LMCorO decimal(10), 
	@LMCorR decimal(10), @LMCorQ decimal(10), @gfetch int

	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @CasIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @SomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @LmStatSal=dbo.iauParL('PS','LOCMSALAR')
	set @SpSpecSalBaza=dbo.iauParL('PS','S-BAZA-SP')
	set @IndCondSalBaza=dbo.iauParL('PS','SBAZA-IND')
	set @Sp1SalBaza=dbo.iauParL('PS','S-BAZA-S1')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	select 
		@NCTaxePLMCh=max(case when Parametru='N-C-TXLMC' then Val_logica else 0 end),
		@NCSubvSomaj=max(case when Parametru='N-SUBVSJD' then Val_logica else 0 end)
	from par where parametru in ('N-C-TXLMC','N-SUBVSJD')

	set @CreditCheltOcazO=dbo.iauParA('PS','N-C-SAL2C')
	select @AtribCreditCheltOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazO
	set @CreditCheltOcazP=dbo.iauParA('PS','N-C-SAL3C')
	select @AtribCreditCheltOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazP
	set @AnLMDebitChelt=dbo.iauParL('PS','N-C-SAL1D')
	set @AnLMDebitCheltOcazO=dbo.iauParL('PS','N-C-SAL2D')
	set @AnLMDebitCheltOcazP=dbo.iauParL('PS','N-C-SAL3D')
	set @AnLMDebitCMUnitate1=dbo.iauParL('PS','N-C-CMU1D')
	set @DebitCMUnitate2=dbo.iauParA('PS','N-C-CMU2D')
	set @CreditCMUnitate2=dbo.iauParA('PS','N-C-CMU2C')
	set @DebitCMCas2=dbo.iauParA('PS','N-C-CMC2D')
	set @CreditCMCas2=dbo.iauParA('PS','N-C-CMC2C')

	if object_id('tempdb..#config_nc_ch') is not null drop table #config_nc_ch

	select distinct a.Loc_de_munca, c.Numar_pozitie, c.Identificator, c.Cont_debitor, c.Cont_creditor, c.denumire, c.Comanda, c.Cont_CAS, c.Cont_CASS, c.Cont_somaj, c.Cont_impozit
	into #config_nc_ch
	from brut a
		outer apply (select * from config_nc c where (a.Loc_de_munca like RTRIM(c.Loc_de_munca)+'%' 
			or c.Loc_de_munca is null and not exists (select 1 from config_nc c1 where a.Loc_de_munca like RTRIM(c1.Loc_de_munca)+'%'))) c
	where a.data=@dataSus

	IF CURSOR_STATUS('global', 'CheltLMBug') >= 0
		CLOSE CheltLMBug
	IF CURSOR_STATUS('global', 'CheltLMBug') >= - 1
		DEALLOCATE CheltLMBug

	declare CheltLMBug cursor for
	select a.Data, a.Marca, a.Loc_de_munca, convert(char(1),a.Loc_munca_pt_stat_de_plata), a.VENIT_TOTAL, 
	a.Realizat__regie+a.Realizat_acord+a.Ind_intrerupere_tehnologica+a.Ind_invoiri+a.Salar_categoria_lucrarii-
	(case when @IndCondSalBaza=1 then round(a.Ind_nemotivate,0) else 0 end)-(case when @SpSpecSalBaza=1 then round(a.Spor_specific,0) else 0 end)-
	(case when @Sp1SalBaza=1 then round(a.Spor_cond_1,0) else 0 end), 
	(a.Indemnizatie_ore_supl_1+a.Indemnizatie_ore_supl_2+a.Indemnizatie_ore_supl_3+a.Indemnizatie_ore_supl_4+ a.Indemnizatie_ore_spor_100), 
	a.Ind_obligatii_cetatenesti+a.Ind_concediu_de_odihna, a.Ind_c_medical_unitate, a.CMunitate, a.Ind_c_medical_CAS, a.CMCAS, 
	a.CO-isnull(cz.suma_corectie,0), isnull(cz.suma_corectie,0), a.Restituiri, -a.Diminuari, a.Suma_impozabila, 
	a.Premiu-isnull(cx.suma_corectie,0), isnull(cx.suma_corectie,0), a.Diurna-isnull(cy.suma_corectie,0), 
	isnull(cy.suma_corectie,0), a.Cons_admin, a.Sp_salar_realizat, a.Suma_imp_separat, 
	(case when @IndCondSalBaza=1 or 1=1 then round(a.Ind_nemotivate,0) else 0 end), 
	(case when @SpSpecSalBaza=1 or 1=1 then round(a.Spor_specific,0) else 0 end), 
	a.Spor_vechime, a.Ind_ore_de_noapte+a.Spor_de_noapte, a.Spor_sistematic_peste_program, a.Spor_de_functie_suplimentara, 
	(case when @Sp1SalBaza=1 or 1=1 then round(a.Spor_cond_1,0) else 0 end), 
	round(a.Spor_cond_2,0), round(a.Spor_cond_3,0), round(a.Spor_cond_4,0), 
	round(a.Spor_cond_5,0), round(a.Spor_cond_6,0), round(a.Spor_cond_7,0), round(a.Spor_cond_8,0),
	0/*(a.Ind_ore_de_noapte+a.Spor_de_noapte+a.Spor_sistematic_peste_program+a.Spor_de_functie_suplimentara+ 
	(case when @IndCondSalBaza=1 then 0 else round(a.Ind_nemotivate,0) end)+(case when @SpSpecSalBaza=1 then 0 else round(a.Spor_specific,0) end)+ (case when @Sp1SalBaza=1 then 0 else round(a.Spor_cond_1,0) end)+round(a.Spor_cond_2,0)+round(a.Spor_cond_3,0)+round(a.Spor_cond_4,0)+
	round(a.Spor_cond_5,0)+round(a.Spor_cond_6,0)+round(a.Spor_cond_7,0))*/, 
	a.Compensatie, isnull(q.Suma_corectie,0), a.Spor_cond_9, i.grupa_de_munca, n.Loc_de_munca, n.Venit_total, n.Cas, n.Somaj_5, n.Fond_de_risc_1, n.Camera_de_munca_1, n.Asig_sanatate_pl_unitate, n.Suma_neimpozabila, n.Ded_suplim, isnull(n1.Cas,0), isnull(n1.Somaj_5,0), isnull(b.ind_c_medical_unitate,0), isnull(b.ind_c_medical_cas,0), isnull(b.CMCAS,0), isnull(b.CMunitate,0), isnull(b.spor_cond_9,0), n.Ded_baza, p.Somaj_1, p.As_sanatate, isnull(n1.Baza_CAS_cond_norm+n1.Baza_CAS_cond_deoseb+n1.Baza_CAS_cond_spec,0), n.Somaj_1, n.Chelt_prof, isnull(s.Scutire_art80,0)+isnull(s.Scutire_art85,0)
	from #brut a
		left outer join personal p on p.marca=a.marca
		left outer join infopers f on f.marca=a.marca
		left outer join istpers i on i.Data=a.Data and i.Marca=a.Marca
		left outer join #net n on n.data=a.data and n.marca=a.marca
		left outer join #net n1 on n1.data=dbo.bom(a.data) and n1.marca=a.marca
		left outer join #net n2 on n2.data=dbo.bom(a.data)+1 and n2.marca=a.marca
		left outer join #brut b on b.data=a.data and b.marca=a.marca and (@LmStatSal=1 and b.Ind_c_medical_unitate+b.CMunitate+b.Ind_c_medical_CAS+b.CMCAS+b.Spor_cond_9<>0 or 
			@LmStatSal=0 and b.loc_de_munca=n.loc_de_munca)
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'X-', '', '', 1) cx on cx.marca=a.marca and cx.Loc_de_munca=a.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Y-', '', '', 1) cy on cy.marca=a.marca and cy.Loc_de_munca=a.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Z-', '', '', 1) cz on cz.marca=a.marca and cz.Loc_de_munca=a.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', '', '', 1) q on q.Data=a.Data and q.Marca=a.Marca and q.Loc_de_munca=a.Loc_de_munca 
		left outer join dbo.fScutiriSomaj (@dataJos, @dataSus, '', 'ZZZ', '', 'ZZZ') s on s.Data=a.Data and s.Marca=a.Marca
	where a.data=@dataSus and (@pMarca='' or a.marca=@pMarca)
	order by a.loc_de_munca, a.Marca

	open CheltLMBug
	fetch next from CheltLMBug into @Data, @Marca, @Lm, @LmStatPl, @VenitTotalBrut, @SalBazaRealizat, @IndOreSupl, @IndCO, @IndCMUnitate, @CMunitate, @IndCMCAS, 
		@CMCAS, @CorD, @CorZ, @Restituiri, @Diminuari, @SumaImpozabila, @Premiu, @Premiu2, @Diurna, @Diurna2, @ConsAdmin, @SpSalarRealizat, @SumaImpSeparat, 
		@IndCond, @SporSpecific, @SporVechime, @SporDeNoapte, @SporSistPrg, @SporFunctieSupl, @SporCond1, @SporCond2, @SporCond3, @SporCond4, @SporCond5, @SporCond6, @SporCond7, @SporCond8, @AlteSporuri, 
		@AjDeces, @AjutoareMat, @IndCMFaambp, @Grupa_de_munca, @LmNet, @VenitTotalNet, @Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, @SumaNeimpozabila, @CCI, @CasCM, @FondGarantare,
		@IndCMUnitateMarca, @IndCMCasMarca, @CMCASMarca, @CMunitateMarca, @IndCMFaambpMarca, @DedPers, @SomajPers, @AsSanatatePers, @BazaCasCM, @Somaj_1, @SubvSomaj, @ScutireSomaj
	Set @gfetch=@@fetch_status
	Set @gMarca=@Marca
	Set @gLm=@Lm
	While @gfetch = 0 
	Begin
		select @LMSalRealiz=0, @LMSalRealizOcazO=0, @LMSalRealizOcazP=0, @LMCMUnitate=0, @LMIndOreSupl=0, @LMIndCO=0, @LMIndCond=0, 
		@LMSporSpec=0, @LMSporVech=0, @LMSporDeNoapte=0, @LMSporSistPrg=0, @LMSporFunctieSupl=0, 
		@LMSporCond1=0, @LMSporCond2=0, @LMSporCond3=0, @LMSporCond4=0, @LMSporCond5=0, @LMSporCond6=0, @LMSporCond7=0, @LMSporCond8=0, 
		@LMAlteSporuri=0, @LMCMFnuass=0, @LMCMFaambp=0, @LMCorD=0, @LMCorZ=0, @LMCorF=0, @LMCorG=0, @LMCorH=0, @LMCorI=0, @LMCorX=0, 
		@LMCorJ=0, @LMCorY=0, @LMCorK=0, @LMCorL=0, @LMCorO=0, @LMCorR=0, @LMCorQ=0
		while @Lm = @gLm and @gfetch = 0
		Begin
--	NC pe marci
			if @AtribCreditCheltOcazP=1 
				set @LMSalRealizOcazP=0
			if @AtribCreditCheltOcazO=1 
				set @LMSalRealizOcazO=0

			set @LMSalRealiz=@LMSalRealiz+(case when @Grupa_de_munca in ('O','P') then 0 else @SalBazaRealizat end)
			set @LMSalRealizOcazO=@LMSalRealizOcazO+(case when @Grupa_de_munca='O' 
				or @Grupa_de_munca='P' and not exists (select Cont_debitor from #config_nc_ch where Numar_pozitie=4 and Loc_de_munca=@lm) then @SalBazaRealizat else 0 end)
			set @LMSalRealizOcazP=@LMSalRealizOcazP+(case when @Grupa_de_munca='P' and exists (select Cont_debitor from #config_nc_ch where Numar_pozitie=4 and Loc_de_munca=@lm) then @SalBazaRealizat else 0 end)
			set @LMCMUnitate=@LMCMUnitate+@IndCMUnitate+@CMunitate
			set @LMIndOreSupl=@LMIndOreSupl+@IndOreSupl
			set @LMIndCO=@LMIndCO+@IndCO
			set @LMIndCond=@LMIndCond+@IndCond
			set @LMSporSpec=@LMSporSpec+@SporSpecific
			set @LMSporVech=@LMSporVech+@SporVechime
			set @LMSporDeNoapte=@LMSporDeNoapte+@SporDeNoapte
			set @LMSporSistPrg=@LMSporSistPrg+@SporSistPrg
			set @LMSporFunctieSupl=@LMSporFunctieSupl+@SporFunctieSupl
			set @LMSporCond1=@LMSporCond1+@SporCond1
			set @LMSporCond2=@LMSporCond2+@SporCond2
			set @LMSporCond3=@LMSporCond3+@SporCond3
			set @LMSporCond4=@LMSporCond4+@SporCond4
			set @LMSporCond5=@LMSporCond5+@SporCond5
			set @LMSporCond6=@LMSporCond6+@SporCond6
			set @LMSporCond7=@LMSporCond7+@SporCond7
			set @LMSporCond8=@LMSporCond8+@SporCond8
			set @LMAlteSporuri=@LMAlteSporuri+@AlteSporuri
			set @LMCMFnuass=@LMCMFnuass+@IndCMCAS+@CMCAS
			set @LMCMFaambp=@LMCMFaambp+@IndCMFaambp
			set @LMCorD=@LMCorD+@CorD
			set @LMCorZ=@LMCorZ+@CorZ
			set @LMCorF=@LMCorF+@Restituiri
			set @LMCorG=@LMCorG+@Diminuari
			set @LMCorH=@LMCorH+@SumaImpozabila
			set @LMCorI=@LMCorI+@Premiu
			set @LMCorX=@LMCorX+@Premiu2
			set	@LMCorJ=@LMCorJ+@Diurna
			set @LMCorY=@LMCorY+@Diurna2
			set @LMCorK=@LMCorK+@ConsAdmin
			set @LMCorL=@LMCorL+@SpSalarRealizat
			set @LMCorO=@LMCorO+@SumaImpSeparat
			set @LMCorR=@LMCorR+@AjDeces
			set @LMCorQ=@LMCorQ+@AjutoareMat
			set @ProcCASIndiv=(case when @Grupa_de_munca<>'O' then @CasIndiv else 0 end)
			set @ProcSomajIndiv=(case when @SomajPers=1 then @SomajInd else 0 end)
			exec scriuCASBrut
				@Data, @Marca, @Lm, @LmStatPl, @VenitTotalBrut, @IndCMUnitate, @CMUnitate, @IndCMCas, @CMCas, @IndCMFaambp, @VenitTotalNet, 
				@Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, @CCI, @CASCM, @FondGarantare, @IndCMUnitateMarca, @CMunitateMarca, @IndCMCasMarca, @CMCasMarca, 
				@IndCMFaambpMarca, 0, 0, @DedPers, @ProcCASIndiv, @ProcSomajIndiv, @AsSanatatePers, @BazaCASCM, @Somaj_1, @SubvSomaj, @ScutireSomaj, @NCTaxePLMCh, @NCSubvSomaj

			Set @ContCreditor=''
			Set @Explicatii=''
			if @AtribCreditCheltOcazO=1 and @Continuare=1 
			Begin
				select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch c where Numar_pozitie=2 and Loc_de_munca=@lm
				set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@lm)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSalRealizOcazO, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @Lm, '', @IndBug, @AnLMDebitCheltOcazO, @Marca, '', 0
			End
			if @AtribCreditCheltOcazP=1 and @Continuare=1 
			Begin
				select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=4 and Loc_de_munca=@lm
				set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@lm)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSalRealizOcazP, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @Lm, '', @IndBug, @AnLMDebitCheltOcazP, @Marca, '', 0
			End
			fetch next from CheltLMBug into @Data, @Marca, @Lm, @LmStatPl, @VenitTotalBrut, @SalBazaRealizat, @IndOreSupl, @IndCO, @IndCMUnitate, @CMunitate, @IndCMCAS, 
				@CMCAS, @CorD, @CorZ, @Restituiri, @Diminuari, @SumaImpozabila, @Premiu, @Premiu2, @Diurna, @Diurna2, @ConsAdmin, @SpSalarRealizat, @SumaImpSeparat, 
				@IndCond, @SporSpecific, @SporVechime, @SporDeNoapte, @SporSistPrg, @SporFunctieSupl, @SporCond1, @SporCond2, @SporCond3, @SporCond4, @SporCond5, @SporCond6, @SporCond7, @SporCond8, 
				@AlteSporuri, @AjDeces, @AjutoareMat, @IndCMFaambp, @Grupa_de_munca, @LmNet, @VenitTotalNet, @Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, 
				@SumaNeimpozabila, @CCI, @CasCM, @FondGarantare, @IndCMUnitateMarca, @IndCMCasMarca, @CMCASMarca, @CMunitateMarca, @IndCMFaambpMarca, 
				@DedPers, @SomajPers, @AsSanatatePers, @BazaCasCM, @Somaj_1, @SubvSomaj, @ScutireSomaj
		set @gfetch=@@fetch_status
		End
--	NC pe locuri de munca
		if @Continuare=1
		Begin
			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=1 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)

			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSalRealiz, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			if @AtribCreditCheltOcazO<>1
			Begin
				select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=2 and Loc_de_munca=@glm
				set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSalRealizOcazO, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitCheltOcazO, '', '', 0
			End
			if @AtribCreditCheltOcazP<>1
			Begin
				select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=4 and Loc_de_munca=@glm
				set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
				exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSalRealizOcazP, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitCheltOcazP, '', '', 0
			End

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=3 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCMUnitate, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitCMUnitate1, '', '', 0
			exec scriuNCsalarii @Data, @DebitCMUnitate2, @CreditCMUnitate2, @LMCMUnitate, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitCMUnitate1, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=5 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMIndOreSupl, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=6 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporDeNoapte, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=7 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMIndCond, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=8 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporSpec, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=9 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporSistPrg, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=10 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporVech, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=11 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporFunctieSupl, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=12 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond1, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=13 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond2, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=14 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond3, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=15 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMAlteSporuri, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=16 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond4, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=17 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond5, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=18 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond6, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=19 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond7, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=21 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMSporCond8, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=20 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMIndCO, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=22 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCMFnuass, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0
			exec scriuNCsalarii @Data, @DebitCMCas2, @CreditCMCas2, @LMCMFnuass, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=23 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@glm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCMFaambp, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0
			exec scriuNCsalarii @Data, @DebitCMCas2, @CreditCMCas2, @LMCMFaambp, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=25 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@glm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorD, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=27 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorZ, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=30 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorF, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=32 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorG, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=35 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorH, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=40 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorI, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=42 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorX, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=45 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorJ, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=47 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorY, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=50 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorK, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=51 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorL, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=60 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorO, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMDebitChelt, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=65 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorR, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0
			exec scriuNCsalarii @Data, @ContCreditor, @CreditCMCas2, @LMCorR, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0

			select @IndBug=Comanda, @DenSuma=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from #config_nc_ch where Numar_pozitie=67 and Loc_de_munca=@glm
			set @Explicatii=rtrim(@DenSuma)+' - '+rtrim(@gLm)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @LMCorQ, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, 0, '', '', 0
		End
		Set @gMarca=@Marca
		Set @gLm=@Lm
	End
	IF CURSOR_STATUS('global', 'CheltLMBug') >= 0
		CLOSE CheltLMBug
	IF CURSOR_STATUS('global', 'CheltLMBug') >= - 1
		DEALLOCATE CheltLMBug
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenNCCheltLMBug (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec GenNCCheltLMBug '02/01/2011', '02/28/2011', '', 1, 309014
*/
