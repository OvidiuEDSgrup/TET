/* operatie pt. generare NC pt. asigurari angajator pe locuri de munca */
Create procedure GenNCCasLM
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output, @TSomajUnitate decimal(10,2) output, @NumarDoc char(8)
As
Begin try
	declare @Sub char(9), @STOUG28 int, @AcordGLTesaAcord int, @RealizGLNormaTimp int, @NuCAS_H int, 
		@pCCI decimal(5,2), @pCass decimal(5,2), @pFaambp decimal(7,3), @pITM decimal(5,2), @pSomaj decimal(5,2), @pFondGar decimal(5,2), 
		@NCIndBug int, @NCAnActiv int, @NCAnActivCtChelt int, @RepManIndCom int, @RepManIndComTL int, @NumaiPontajeAcord int, 
		@RepAsigUnitCom int, @NCSubvSomaj int, @Pasmatex int, @Reva int, @Remarul int, 
		@Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), 
		@DenSuma char(30), @gLm char(9), @gMarca char(6), @IndBug char(20), 

-- variabile pt. scriere NC
	@DebitCASPerm varchar(20), @CreditCASPerm varchar(20), @AnLMCASPerm int, 
	@DebitCASOcaz varchar(20), @CreditCASOcaz varchar(20), @AnLMCASOcaz int, 
	@DebitCASSPerm varchar(20), @CreditCASSPerm varchar(20), @AnLMCASSPerm int, 
	@DebitCASSOcaz varchar(20), @CreditCASSOcaz varchar(20), @AnLMCASSOcaz int, 
	@DebitCCI varchar(20), @CreditCCI varchar(20), @AnLMCCI int, 
	@DebitFaambpPerm varchar(20), @CreditFaambpPerm varchar(20), @AnLMFaambpPerm int, 
	@DebitFaambpOcaz varchar(20), @CreditFaambpOcaz varchar(20), @AnLMFaambpOcaz int, 
	@DebitITM varchar(20), @CreditITM varchar(20), @AnLMITM int, 
	@DebitSomajPerm varchar(20), @CreditSomajPerm varchar(20), @AnLMSomajPerm int, 
	@DebitSomajOcaz varchar(20), @CreditSomajOcaz varchar(20), @AnLMSomajOcaz int, 
	@DebitSubvSomaj varchar(20), @CreditSubvSomaj varchar(20), 
	@DebitFondGar varchar(20), @CreditFondGar varchar(20), @AnLMFondGar int, 
	@AnActivDeb char(10), @AnActivCre char(10), 
-- variabile din fetch
	@Lm char(9), @Marca char(6), @VenitLM decimal(10), 
	@Cas decimal(8,2), @Somaj_5 decimal(8,2), @Faambp decimal(8,2), @ComisionITM decimal(8,2), 
	@CassUnitate decimal(8,2), @CCI decimal(8,2), @CasCM decimal(8,2), @FondGarantare decimal(8,2), 
	@Grupa_de_munca char(1), @CasaSanatate char(30), @Activitate varchar(10), @gActivitate varchar(10), 
	@IndCMUnitate decimal(10), @IndCMCas decimal(10), @CMCAS decimal(10), @CMUnitate decimal(10), 
	@Suma_impozabila decimal(10), @IndCMFaambp decimal(10), 
	@SomajTehnic decimal(10), @AreRealizariCom int, @TipSalarizarePontaj char(1), 
	@gVenitRealizatLm decimal(10,2), @VenitRealizatLm decimal(10,2), @VenitNelucratMLM decimal(10,2), @CorectiiMLM decimal(10,2), 
	@RealizatRegie decimal(10,2), @RealizatAcord decimal(10,2), @IndOreSuplMLM decimal(10,2), @SporuriMLM decimal(10,2), 
	@Pensionar int, @SubvSomaj decimal(10), @ScutireSomaj decimal(10), @SumeExcPontajeAcMLM decimal(10), 
--variabile pt. totaluri pe LM
	@LMCasPerm decimal(10,2), @LMCasOcaz decimal(10,2), @LMCassPerm decimal(10,2), 
	@LMCassOcaz decimal(10,2), @LMCassPDafora decimal(10,2), @LMCassODafora decimal(10,2), 
	@LMFaambpPerm decimal(10,2), @LMFaambpOcaz decimal(10,2), @LMComisionITM decimal(10,2), 
	@LMSomajPerm decimal(10,2), @LMSomajOcaz decimal(10,2), @LMCCIPerm decimal(10,2), @LMCCIOcaz decimal(10,2), @LMFondGar decimal(10,2), 
	@LMSubvSomaj decimal(10,2), @LMScutireSomaj decimal(10,2), @LMVenit decimal(10,2), @LMVenitSomaj decimal(10,2), 
	@LMVenitITM decimal(10,2), @LMVenitRealiz decimal(10,2), @gfetch int

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @STOUG28=dbo.iauParLN(@dataSus,'PS','@STOUG28')
	set @AcordGLTesaAcord=dbo.iauParL('PS','ACGLOTESA')
	set @RealizGLNormaTimp=dbo.iauParL('PS','RZANORMT')
	set @pCCI=dbo.iauParLN(@dataSus,'PS','COTACCI')
	set @pCass=dbo.iauParLN(@dataSus,'PS','CASSUNIT')
	set @pFaambp=dbo.iauParLN(@dataSus,'PS','0.5%ACCM')
	set @pITM=dbo.iauParLN(@dataSus,'PS','1%CAMERA')
	set @pSomaj=dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ')
	set @pFondGar=dbo.iauParLN(@dataSus,'PS','FONDGAR')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')
	set @RepManIndCom=dbo.iauParL('PS','NC-MI-COM')
	set @RepManIndComTL=dbo.iauParL('PS','NC-MC-TLC')
	set @NumaiPontajeAcord=dbo.iauParL('PS','NC-MC-PA')
	set @RepAsigUnitCom=dbo.iauParL('PS','NC-AU-COM')
	set @NCSubvSomaj=dbo.iauParL('PS','N-SUBVSJD')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @Reva=dbo.iauParL('SP','REVA')
	set @Remarul=dbo.iauParL('SP','REMARUL')

	set @DebitCASPerm=dbo.iauParA('PS','N-AS-33%D')
	set @AnLMCASPerm=dbo.iauParL('PS','N-AS-33%D')
	set @CreditCASPerm=dbo.iauParA('PS','N-AS-33%C')
	set @DebitCASOcaz=dbo.iauParA('PS','N-ASO33%D')
	set @AnLMCASOcaz=dbo.iauParL('PS','N-ASO33%D')
	set @CreditCASOcaz=dbo.iauParA('PS','N-ASO33%C')
	set @DebitCCI=dbo.iauParA('PS','N-AS-CCID')
	set @AnLMCCI=dbo.iauParL('PS','N-AS-CCID')
	set @CreditCCI=dbo.iauParA('PS','N-AS-CCIC')
	set @DebitCASSPerm=dbo.iauParA('PS','N-AS-AS5D')
	set @AnLMCASSPerm=dbo.iauParL('PS','N-AS-AS5D')
	set @CreditCASSPerm=dbo.iauParA('PS','N-AS-AS5C')
	set @DebitCASSOcaz=dbo.iauParA('PS','N-ASOAS5D')
	set @AnLMCASSOcaz=dbo.iauParL('PS','N-ASOAS5D')
	set @CreditCASSOcaz=dbo.iauParA('PS','N-ASOAS5C')
	set @DebitFaambpPerm=dbo.iauParA('PS','N-AS-FR1D')
	set @AnLMFaambpPerm=dbo.iauParL('PS','N-AS-FR1D')
	set @CreditFaambpPerm=dbo.iauParA('PS','N-AS-FR1C')
	set @DebitFaambpOcaz=dbo.iauParA('PS','N-ASOFR1D')
	set @AnLMFaambpOcaz=dbo.iauParL('PS','N-ASOFR1D')
	set @CreditFaambpOcaz=dbo.iauParA('PS','N-ASOFR1C')
	set @DebitITM=dbo.iauParA('PS','N-MUNCA-D')
	set @AnLMITM=dbo.iauParL('PS','N-MUNCA-D')
	set @CreditITM=dbo.iauPara('PS','N-MUNCA-C')
	set @DebitSomajPerm=dbo.iauParA('PS','N-ASSJP5D')
	set @AnLMSomajPerm=dbo.iauParL('PS','N-ASSJP5D')
	set @CreditSomajPerm=dbo.iauParA('PS','N-ASSJP5C')
	set @DebitSomajOcaz=dbo.iauParA('PS','N-ASSJO5D')
	set @AnLMSomajOcaz=dbo.iauParL('PS','N-ASSJO5D')
	set @CreditSomajOcaz=dbo.iauParA('PS','N-ASSJO5C')
	set @DebitSubvSomaj=dbo.iauParA('PS','N-SUBVSJD')
	set @CreditSubvSomaj=dbo.iauParA('PS','N-SUBVSJC')
	set @DebitFondGar=dbo.iauParA('PS','N-ASFGARD')
	set @AnLMFondGar=dbo.iauParL('PS','N-ASFGARD')
	set @CreditFondGar=dbo.iauParA('PS','N-ASFGARC')

	if object_id('tempdb..#config_nc_cas') is not null drop table #config_nc_cas

	select distinct a.Loc_de_munca, c.Numar_pozitie, c.Identificator, c.Cont_debitor, c.Cont_creditor, c.denumire, c.Comanda, c.Cont_CAS, c.Cont_CASS, c.Cont_somaj, c.Cont_impozit
	into #config_nc_cas
	from casbrut a
		outer apply (select * from config_nc c where (a.Loc_de_munca like RTRIM(c.Loc_de_munca)+'%' 
			or c.Loc_de_munca is null and not exists (select 1 from config_nc c1 where a.Loc_de_munca like RTRIM(c1.Loc_de_munca)+'%'))) c

	IF CURSOR_STATUS('global', 'CasLM') >= 0
		CLOSE CasLM
	IF CURSOR_STATUS('global', 'CasLM') >= - 1
		DEALLOCATE CasLM

	declare CasLM cursor for
	select a.Loc_de_munca, a.Marca, a.Venit_locm, a.CAS, a.Somaj_5, a.Fond_de_risc_1, a.Camera_de_Munca_1, a.Asig_sanatate_pl_unitate, a.CCI, a.Fond_de_garantare, p.Grupa_de_munca, p.Adresa, 
	(case when @NCAnActiv=1 then p.Activitate else '' end) as Activitate, isnull(b.ind_c_medical_unitate,0), isnull(b.ind_c_medical_cas,0), 
	isnull(b.CMCAS,0), isnull(b.CMunitate,0), isnull(b.suma_impozabila,0), isnull(b.spor_cond_9,0), (case when @STOUG28=1 then isnull(b.Ind_invoiri,0) else 0 end), 
	isnull((select count(1) from realcom r where r.data between @dataJos and @dataSus and r.marca=a.marca and r.loc_de_munca=a.loc_de_munca),0), 
	isnull((select max(p.tip_salarizare) from pontaj p where (@RepManIndCom=1 or @RepManIndComTL=1) and p.data between @dataJos and @dataSus 
		and p.marca=a.marca and (@Remarul=0 and p.loc_de_munca=a.loc_de_munca or @Remarul=0 and p.loc_de_munca like rtrim(a.loc_de_munca)+'%')),'') as tip_salarizare_pontaj, 
	isnull((select sum(round((case when @RealizGLNormaTimp=1 then r.Cantitate*r.Norma_de_timp*(r1.Valoare_manopera/r1.Ore_realizate_in_acord) else r.Cantitate*r.Tarif_unitar end),2))
		from realcom r
			left outer join reallmun r1 on r1.Data=@dataSus and r1.Loc_de_munca=r.Loc_de_munca
			left outer join brut b1 on b1.Data=@dataSus and b1.Marca=r.Marca and b1.Loc_de_munca=r.Loc_de_munca
		where r.Data between @dataJos and @dataSus and r.Marca='' and r.Loc_de_munca=a.Loc_de_munca),0) as Venit_realizat_locm, 
	(b.ind_concediu_de_odihna+b.ind_intrerupere_tehnologica+ind_obligatii_cetatenesti+b.ind_invoiri), 
	(b.CO+b.Restituiri+b.Diminuari+(case when @NuCAS_H=1 then 0 else b.Suma_impozabila end)+b.Diurna+b.Cons_admin+b.Suma_imp_separat+(case when 1=0 then b.Premiu+b.Sp_salar_realizat else 0 end)), 
	b.Realizat__regie, b.Realizat_acord, 
	b.Indemnizatie_ore_supl_1+b.Indemnizatie_ore_supl_2+b.Indemnizatie_ore_supl_3+b.Indemnizatie_ore_supl_4+b.Indemnizatie_ore_spor_100+b.Ind_ore_de_noapte, 
	b.Spor_vechime+b.Spor_de_noapte+b.Spor_sistematic_peste_program+ b.Spor_de_functie_suplimentara+b.Spor_specific
		+b.Spor_cond_1+b.Spor_cond_2+b.Spor_cond_3+b.Spor_cond_4+b.Spor_cond_5+ b.Spor_cond_6+(case when 1=1 then b.Premiu+b.Sp_salar_realizat else 0 end), 
		p.Coef_invalid, a.Subventie_somaj, a.Scutire_somaj
	from casbrut a
		left outer join personal p on p.marca=a.marca
		left outer join infopers ip on ip.marca=a.marca
		left outer join #brut b on b.data=@dataSus and b.marca=a.marca and b.loc_de_munca=a.loc_de_munca
	where (@pMarca='' or a.marca=@pMarca) 
	order by Activitate, a.Loc_de_munca

	open CasLM
	fetch next from CasLM into @Lm, @Marca, @VenitLM, @Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, @CCI, @FondGarantare, 
		@Grupa_de_munca, @CasaSanatate, @Activitate, @IndCMUnitate, @IndCMCas, @CMCAS, @CMUnitate, @Suma_impozabila, 
		@IndCMFaambp, @SomajTehnic, @AreRealizariCom, @TipSalarizarePontaj, @VenitRealizatLm, @VenitNelucratMLM, @CorectiiMLM, 
		@RealizatRegie, @RealizatAcord, @IndOreSuplMLM, @SporuriMLM, @Pensionar, @SubvSomaj, @ScutireSomaj
	set @gfetch=@@fetch_status
	set @gMarca=@Marca
	set @gLm=@Lm
	set @gActivitate=@Activitate
	While @gfetch = 0 
	Begin
		select @LMCasPerm=0, @LMCasOcaz=0, @LMCassPerm=0, @LMCassOcaz=0, @LMCassPDafora=0, @LMCassODafora=0, 
			@LMFaambpPerm=0, @LMFaambpOcaz=0, @LMComisionITM=0, @LMSomajPerm=0, @LMSomajOcaz=0, @LMCCIPerm=0, @LMCCIOcaz=0, @LMFondGar=0, 
			@LMSubvSomaj=0, @LMScutireSomaj=0, @LMVenit=0, @LMVenitSomaj=0, @LMVenitITM=0, @LMVenitRealiz=0
		while @Lm = @gLm and @gfetch = 0
		Begin
--	NC pe marci
			set @SumeExcPontajeAcMLM=@RealizatRegie+(case when @RealizatAcord=0 then @IndOreSuplMLM+@SporuriMLM 
				else (case when @RealizatRegie=0 and @RealizatAcord<>0 then 0 else (@IndOreSuplMLM+@SporuriMLM)*@RealizatRegie/(@RealizatRegie+@RealizatAcord) end) end)
			if not(@Grupa_de_munca in ('O','P'))
			Begin
				set @LMCasPerm=@LMCasPerm+@Cas
				set @LMFaambpPerm=@LMFaambpPerm+@Faambp
				set @LMSomajPerm=@LMSomajPerm+@Somaj_5
			End	
			if @Grupa_de_munca in ('O','P')
			Begin
				set @LMCasOcaz=@LMCasOcaz+@Cas 
				set @LMFaambpOcaz=@LMFaambpOcaz+@Faambp
				set @LMSomajOcaz=@LMSomajOcaz+@Somaj_5
			End
			select @TSomajUnitate=@TSomajUnitate+@Somaj_5 where @NCSubvSomaj=1
			if not(@Grupa_de_munca in ('O','P')) and (@Reva=0 or @CasaSanatate='CNAS')
				set @LMCassPerm=@LMCassPerm+@CassUnitate 
			if @Grupa_de_munca in ('O','P') and (@Reva=0 or @CasaSanatate='CNAS')
				set @LMCassOcaz=@LMCassOcaz+@CassUnitate 
			if @Reva=1 and @CasaSanatate<>'CNAS' and not(@Grupa_de_munca in ('O','P'))
				set @LMCassPDafora=@LMCassPDafora+@CassUnitate
			if @Reva=1 and @CasaSanatate<>'CNAS' and @Grupa_de_munca in ('O','P')
				set @LMCassODafora=@LMCassODafora+@CassUnitate
			set @LMComisionITM=@LMComisionITM+@ComisionITM
			if @NCIndBug=0 or not(@Grupa_de_munca in ('O','P'))
				select @LMCCIPerm=@LMCCIPerm+@CCI
			if @NCIndBug=1 and @Grupa_de_munca in ('O','P')
				select @LMCCIOcaz=@LMCCIOcaz+@CCI
			select @LMFondGar=@LMFondGar+@FondGarantare where @Grupa_de_munca<>'O'
			set @LMSubvSomaj=@LMSubvSomaj+@SubvSomaj
			set @LMScutireSomaj=@LMScutireSomaj+@ScutireSomaj
			if not(@AreRealizariCom<>0) and (@AcordGLTesaAcord=1 or @TipSalarizarePontaj<>'2')
			Begin
				set @LMVenit=@LMVenit+@VenitLM-((case when @NuCAS_H=1 then @Suma_impozabila else 0 end)+
				@IndCMUnitate+@IndCMCas+@CMCAS+@CMUnitate+(case when @RepManIndComTL=1 then 
				@VenitNelucratMLM+@CorectiiMLM+@SomajTehnic+(case when @NumaiPontajeAcord=1 then @SumeExcPontajeAcMLM else 0 end) else 0 end))
				set @LMVenitSomaj=@LMVenitSomaj
				set @LMVenitITM=@LMVenitITM
			End
			set @LMVenitRealiz=@VenitRealizatLm
			set @gVenitRealizatLm=@VenitRealizatLm
			fetch next from CasLM into @Lm, @Marca, @VenitLM, @Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, @CCI, @FondGarantare, @Grupa_de_munca, 
				@CasaSanatate, @Activitate, @IndCMUnitate, @IndCMCas, @CMCAS, @CMUnitate, @Suma_impozabila, @IndCMFaambp, 
				@SomajTehnic, @AreRealizariCom, @TipSalarizarePontaj, @VenitRealizatLm, @VenitNelucratMLM, @CorectiiMLM, @RealizatRegie, @RealizatAcord, 
				@IndOreSuplMLM, @SporuriMLM, @Pensionar, @SubvSomaj, @ScutireSomaj
			set @gfetch=@@fetch_status
		End
		if @Pasmatex=0 and @RepAsigUnitCom=1
			set @LMVenitRealiz=@gVenitRealizatLm
--	procedura pt. asigurari pe lm si com
		if @Pasmatex=0 and @RepAsigUnitCom=1
			exec GenNCCasLMCom @dataJos, @dataSus, @pMarca, @gLm, @gMarca, @gActivitate, 
			@Continuare output, @NrPozitie output, @LMVenit, @LMVenitSomaj, @LMVenitITM, @LMVenitRealiz, 
			@LMCasPerm output, @LMCasOcaz output, @LMCassPerm output, @LMCassOcaz output, @LMCassPDafora output, 
			@LMFaambpPerm output, @LMFaambpOcaz output, @LMComisionITM output, @LMSomajPerm output, @LMSomajOcaz output, 
			@LMCCIPerm output, @LMCCIOcaz output, @LMFondGar output, @LMSubvSomaj output, @LMScutireSomaj output, @NumarDoc

		set @AnActivDeb=(case when @NCAnActiv=1 then '.'+rtrim(@gActivitate) else '' end)
		set @AnActivCre=(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(@gActivitate) else '' end)
		if @Continuare=1
		Begin
			select @IndBug=''
			Set @ContDebitor=rtrim(@DebitCASPerm)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCASPerm)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=100 and Loc_de_munca=@glm
			set @Explicatii='C.A.S. - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCasPerm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMCASPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASOcaz)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCASOcaz)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=102 and Loc_de_munca=@glm
			set @Explicatii='C.A.S. - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCasOcaz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMCASOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitCCI)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCCI)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor), 
					@IndBug=Comanda from #config_nc_cas where Numar_pozitie=120 and Loc_de_munca=@glm
			set @Explicatii='CCI '+(case when @NCIndBug=1 then '- permanenti ' else '' end)+rtrim(convert(char(6),@pCCI))+'% - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCCIPerm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMCCI, '', '', 0

			if @NCIndBug=1
			Begin
				select @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor), 
					@IndBug=Comanda from #config_nc_cas where Numar_pozitie=122 and Loc_de_munca=@glm
				set @Explicatii='CCI - ocazionali '+rtrim(convert(char(6),@pCCI))+'% - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCCIOcaz, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMCCI, '', '', 0
			End

			Set @ContDebitor=rtrim(@DebitCASSPerm)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCASSPerm)+(case when @Reva=1 then '.1' else rtrim(@AnActivCre) end)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=110 and Loc_de_munca=@glm
			set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+'% - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCassPerm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMCassPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASSOcaz)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCASSOcaz)+(case when @Reva=1 then '.1' else rtrim(@AnActivCre) end)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=112 and Loc_de_munca=@glm
			set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+'% - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCassOcaz, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMCassOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASSPerm)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCASSPerm)+(case when @Reva=1 then '.2' else rtrim(@AnActivCre) end)
			set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+'% - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCassPDafora, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCassPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASSOcaz)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCASSOcaz)+(case when @Reva=1 then '.2' else rtrim(@AnActivCre) end)
			set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+'% - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCassODafora, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCassOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitFaambpPerm)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditFaambpPerm)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=115 and Loc_de_munca=@glm
			set @Explicatii='Fd.special acc. de munca '+rtrim(convert(char(6),@pFaambp))+'% - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMFaambpPerm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMFaambpPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitFaambpOcaz)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditFaambpOcaz)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=117 and Loc_de_munca=@glm
			set @Explicatii='Fd.special acc. de munca '+rtrim(convert(char(6),@pFaambp))+'% - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMFaambpOcaz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMFaambpOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitITM)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditITM)+rtrim(@AnActivCre)
			set @Explicatii='Camera de munca '+rtrim(convert(char(6),@pITM))+'% - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMComisionITM, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMITM, '', '', 0

			Set @ContDebitor=rtrim(@DebitSomajPerm)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditSomajPerm)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=105 and Loc_de_munca=@glm
			set @Explicatii='Somaj '+rtrim(convert(char(6),@pSomaj))+'% - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMSomajPerm, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMSomajPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitSomajOcaz)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditSomajOcaz)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=107 and Loc_de_munca=@glm
			set @Explicatii='Somaj '+rtrim(convert(char(6),@pSomaj))+'% - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMSomajOcaz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMSomajOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitFondGar)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditFondGar)+rtrim(@AnActivCre)
			if @NCIndBug=1
				select @IndBug=Comanda, @ContDebitor=rtrim(Cont_debitor), @ContCreditor=rtrim(Cont_creditor) from #config_nc_cas where Numar_pozitie=125 and Loc_de_munca=@glm
			set @Explicatii='Fond de garantare '+rtrim(convert(char(6),@pFondGar))+'% - '+rtrim(@gLm)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMFondGar, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', @IndBug, @AnLMFondGar, '', '', 0
			if @NCSubvSomaj=1
			Begin
				set @Explicatii='Total Subventii Somaj - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @DebitSubvSomaj, @CreditSubvSomaj, @LMSubvSomaj, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0

				set @Explicatii='Total Scutiri Somaj - '+rtrim(@gLm)
				exec scriuNCsalarii @dataSus, @CreditSomajPerm, @CreditSubvSomaj, @LMScutireSomaj, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', 0, '', '', 0
			End
		End
		Set @gMarca=@Marca
		Set @gLm=@Lm
		set @gActivitate=@Activitate
	End
	IF CURSOR_STATUS('global', 'CasLM') >= 0
		CLOSE CasLM
	IF CURSOR_STATUS('global', 'CasLM') >= - 1
		DEALLOCATE CasLM
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenNCCasLM (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec GenNCCheltLMBug '02/01/2011', '02/28/2011', '', 1, 309014
*/
