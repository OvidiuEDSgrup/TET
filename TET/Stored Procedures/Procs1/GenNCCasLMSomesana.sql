/* operatie pt. generare NC pt. asigurari angajator pe locuri de munca Somesana */
Create procedure GenNCCasLMSomesana 
	@DataJ datetime, @DataS datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output,@TSomajUnitate decimal(10,2) output
As
Begin
	declare @Sub char(9), @pCasIndiv decimal(5,2), @pCasCN decimal(5,2), @pCasCD decimal(5,2), @pCasCS decimal(5,2), 
	@pCCI decimal(5,2), @pCass decimal(5,2), @pFaambp decimal(7,3), @pITM decimal(5,2), 
	@pSomaj decimal(5,2), @pFondGar decimal(5,2), @NCAnActiv int, 
	@NumarDoc char(8), @cDataDoc char(4), @Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), @gLm char(9), 
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
	@AnActivDeb char(10), 
	-- variabile din fetch
	@Lm char(9), @Marca char(6), @VenitLM decimal(10), 
	@Cas decimal(8,2), @Somaj_5 decimal(8,2), @Faambp decimal(8,2), @ComisionITM decimal(8,2), 
	@CassUnitate decimal(8,2), @CCI decimal(8,2), @CasCM decimal(8,2), @FondGarantare decimal(8,2), 
	@GrupaMPers char(1), @Activitate varchar(10), @gActivitate varchar(10), 
	@RealizatRegie decimal(10), @RealizatAcord decimal(10), @IndOreSupl1 decimal(10), @IndOreSupl2 decimal(10), @IndOreSupl3 decimal(10), @IndOreSupl4 decimal(10), @IndOreNoapte decimal(10), 
	@IndCMUnitate decimal(10), @IndCMFnuass decimal(10), @IndCMFaambp decimal(10), 
	@GrupaMPontaj char(1), @Pensionar int, @ProcCAS decimal(6,2), 
	@BazaCheltDir decimal(10), @BazaCheltIndDir1 decimal(10), @BazaCheltIndDir2 decimal(10), 
	--variabile pt. totaluri pe LM
	@LMCasPerm decimal(10,2), @LMCasPermInd decimal(10,2), @LMCasOcaz decimal(10,2), 
	@LMCassPerm decimal(10,2), @LMCassPermInd decimal(10,2), @LMCassOcaz decimal(10,2), 
	@LMFaambpPerm decimal(10,2), @LMFaambpPermInd decimal(10,2), @LMFaambpOcaz decimal(10,2), 
	@LMITMPerm decimal(10,2), @LMITMPermInd decimal(10,2), 
	@LMSomajPerm decimal(10,2), @LMSomajPermInd decimal(10,2), @LMSomajOcaz decimal(10,2), 
	@LMCCI decimal(10,2), @LMCCIInd decimal(10,2), @LMFondGar decimal(10,2), @LMFondGarInd decimal(10,2), 
	@TVenitLM decimal(10,2), @gfetch int

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @pCasIndiv=dbo.iauParLN(@DataS,'PS','CASINDIV')
	set @pCasCN=dbo.iauParLN(@DataS,'PS','CASGRUPA3')
	set @pCasCD=dbo.iauParLN(@DataS,'PS','CASGRUPA2')
	set @pCasCS=dbo.iauParLN(@DataS,'PS','CASGRUPA1')
	set @pCCI=dbo.iauParLN(@DataS,'PS','COEFCCI')
	set @pCass=dbo.iauParLN(@DataS,'PS','CASSUNIT')
	set @pFaambp=dbo.iauParLN(@DataS,'PS','0.5%ACCM')
	set @pITM=dbo.iauParLN(@DataS,'PS','1%CAMERA')
	set @pSomaj=dbo.iauParLN(@DataS,'PS','3.5%SOMAJ')
	set @pFondGar=dbo.iauParLN(@DataS,'PS','FONDGAR')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')

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

	set @cDataDoc=left(convert(char(10),@DataS,101),2)+right(convert(char(10),@DataS,101),2)
	set @NumarDoc='SAL'+@cDataDoc

	declare CasLM cursor for
	select a.Loc_de_munca, a.Marca, a.Venit_locm, a.CAS, a.Somaj_5, a.Fond_de_risc_1, a.Camera_de_Munca_1, 
	a.Asig_sanatate_pl_unitate, a.CCI, a.Fond_de_garantare, p.Grupa_de_munca, 
	(case when @NCAnActiv=1 then p.Activitate else '' end) as Activitate, 
	isnull(b.Realizat__regie,0), isnull(b.Realizat_acord,0), 
	isnull(b.Indemnizatie_ore_supl_1,0), isnull(b.Indemnizatie_ore_supl_2,0), isnull(b.Indemnizatie_ore_supl_3,0), 
	isnull(b.Indemnizatie_ore_supl_4,0), isnull(b.Ind_ore_de_noapte,0), 
	isnull(b.ind_c_medical_unitate,0), isnull(b.ind_c_medical_cas,0), isnull(b.spor_cond_9,0), 
	isnull((select max(p.Grupa_de_munca) from pontaj p where p.data between @DataJ and @DataS and p.marca=a.marca and p.loc_de_munca=a.loc_de_munca),'') as tip_salarizare_pontaj, 
	p.Coef_invalid
	from casbrut a
	left outer join personal p on p.marca=a.marca
	left outer join infopers f on f.marca=a.marca
	left outer join brut b on b.data=@DataS and b.marca=a.marca and b.loc_de_munca=a.loc_de_munca
	where (@pMarca='' or a.marca=@pMarca) 
	order by Activitate, a.Loc_de_munca

	open CasLM
	fetch next from CasLM into @Lm, @Marca, @VenitLM, @Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, @CCI, @FondGarantare, @GrupaMPers, @Activitate, @RealizatRegie, @RealizatAcord, 
		@IndOreSupl1, @IndOreSupl2, @IndOreSupl3, @IndOreSupl4, @IndOreNoapte, @IndCMUnitate, @IndCMFnuass, @IndCMFaambp, @GrupaMPontaj, @Pensionar
	set @gfetch=@@fetch_status
	set @gLm=@Lm
	set @gActivitate=@Activitate
	While @gfetch = 0 
	Begin
		select @LMCasPerm=0, @LMCasPermInd=0, @LMCasOcaz=0, @LMCassPerm=0, @LMCassPermInd=0, @LMCassOcaz=0, 
			@LMFaambpPerm=0, @LMFaambpPermInd=0, @LMFaambpOcaz=0, @LMItmPerm=0, @LMItmPermInd=0, 
			@LMSomajPerm=0, @LMSomajPermInd=0, @LMSomajOcaz=0, @LMCCI=0, @LMCCIInd=0, @LMFondGar=0, @LMFondGarInd=0, @TVenitLM=0
		while @Lm = @gLm and @gfetch = 0
		Begin
	--	NC pe marci
			set @ProcCAS=((case when @GrupaMPontaj='S' then @pCasCS when @GrupaMPontaj='D' then @pCasCD when @GrupaMPontaj='N' then @pCasCN end)-@pCasIndiv)
			set @BazaCheltDir=(@RealizatRegie+@IndOreSupl1+@IndOreSupl2+@IndOreSupl3+@IndOreSupl4+@IndOreNoapte)
			set @BazaCheltIndDir1=@VenitLM-(@RealizatRegie+@IndOreSupl1+@IndOreSupl2+@IndOreSupl3+@IndOreSupl4+@IndOreNoapte)
			-(@IndCMUnitate+@IndCMFnuass+@IndCMFaambp)
			set @BazaCheltIndDir2=@VenitLM-(@RealizatRegie+@IndOreSupl1+@IndOreSupl2+@IndOreSupl3+@IndOreSupl4+@IndOreNoapte)
			-(@IndCMFnuass+@IndCMFaambp)
			if @GrupaMPers<>'O'
			Begin
				set @LMCasPerm=@LMCasPerm+(case when @Activitate=31 then @BazaCheltDir*@ProcCAS/100 else 0 end)
				set @LMCasPermInd=@LMCasPermInd+(case when @Activitate=31 then @BazaCheltIndDir1*@ProcCAS/100 else @Cas end)
				set @LMFaambpPerm=@LMFaambpPerm+(case when @Activitate=31 then @BazaCheltDir*@pFaambp/100 else 0 end)
				set @LMFaambpPermInd=@LMFaambpPermInd+(case when @Activitate=31 then @BazaCheltIndDir1*@pFaambp/100 else @Faambp end)
				set @LMSomajPerm=@LMSomajPerm+(case when @Activitate=31 then @BazaCheltDir*@pSomaj/100 else 0 end)
				set @LMSomajPermInd=@LMSomajPermInd+(case when @Activitate=31 then @BazaCheltIndDir2*@pSomaj/100 else @Somaj_5 end)
				set @LMFondGar=@LMFondGar+(case when @Activitate=31 then @BazaCheltDir*@pFondGar/100 else 0 end)
				set @LMFondGarInd=@LMFondGarInd+(case when @Activitate=31 then @BazaCheltIndDir2*@pFondGar/100 else @FondGarantare end)
			End	
			if @GrupaMPers='O'
			Begin
				set @LMCasOcaz=@LMCasOcaz+@Cas 
				set @LMFaambpOcaz=@LMFaambpOcaz+@Faambp
				set @LMSomajOcaz=@LMSomajOcaz+@Somaj_5
			End
			if not(@GrupaMPers in ('O','P'))
			Begin
				set @LMCassPerm=@LMCassPerm+(case when @Activitate=31 then @BazaCheltDir*@pCass/100 else 0 end)
				set @LMCassPermInd=@LMCassPermInd+(case when @Activitate=31 then @BazaCheltIndDir2*@pCass/100 else @CassUnitate end)
			End	
			if @GrupaMPers in ('O','P')
				set @LMCassOcaz=@LMCassOcaz+@CassUnitate 

			set @LMItmPerm=@LMItmPerm+(case when @Activitate=31 then @BazaCheltDir*@pItm/100 else 0 end)
			set @LMItmPermInd=@LMItmPermInd+(case when @Activitate=31 then @BazaCheltIndDir2*@pItm/100 else @ComisionItm end)
		
			set @LMCCI=@LMCCI+(case when @Activitate=31 then @BazaCheltDir*@pCCI/100 else 0 end)
			set @LMCCIInd=@LMCCIInd+(case when @Activitate=31 then @BazaCheltIndDir2*@pCCI/100 else @CCI end)
		
			set @TVenitLM=@TVenitLM+@VenitLM

			fetch next from CasLM into @Lm, @Marca, @VenitLM, @Cas, @Somaj_5, @Faambp, @ComisionITM, @CassUnitate, @CCI, @FondGarantare, @GrupaMPers, @Activitate, 
				@RealizatRegie, @RealizatAcord, @IndOreSupl1, @IndOreSupl2, @IndOreSupl3, @IndOreSupl4, @IndOreNoapte, @IndCMUnitate, @IndCMFnuass, @IndCMFaambp, @GrupaMPontaj, @Pensionar

		set @gfetch=@@fetch_status
		End
		set @AnActivDeb=(case when @NCAnActiv=1 then '.'+rtrim(convert(char(3),@gActivitate)) else '' end)
		if @Continuare=1
		Begin
			Set @ContDebitor=rtrim(@DebitCASPerm)+rtrim(@AnActivDeb)
			set @Explicatii='C.A.S. - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditCASPerm, @LMCasPerm, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCASPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASOcaz)+rtrim(@AnActivDeb)
			set @Explicatii='C.A.S. - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditCASOcaz, @LMCasOcaz, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCASOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitCCI)+rtrim(@AnActivDeb)
			set @Explicatii='CCI '+rtrim(convert(char(6),@pCCI))+' - '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditCCI, @LMCCI, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCCI, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASSPerm)+rtrim(@AnActivDeb)
			set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+' - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditCASSPerm, @LMCassPerm, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCassPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitCASSOcaz)+rtrim(@AnActivDeb)
			set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+' - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditCASSOcaz, @LMCassOcaz, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMCassOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitFaambpPerm)+rtrim(@AnActivDeb)
			set @Explicatii='Fd.special acc de munca '+rtrim(convert(char(6),@pFaambp))+' - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditFaambpPerm, @LMFaambpPerm, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMFaambpPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitFaambpOcaz)+rtrim(@AnActivDeb)
			set @Explicatii='Fd.special acc de munca '+rtrim(convert(char(6),@pFaambp))+' - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditFaambpOcaz, @LMFaambpOcaz, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMFaambpOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitITM)+rtrim(@AnActivDeb)
			set @Explicatii='Camera de munca '+rtrim(convert(char(6),@pITM))+' - '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditITM, @LMItmPerm, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMITM, '', '', 0

			Set @ContDebitor=rtrim(@DebitSomajPerm)+rtrim(@AnActivDeb)
			set @Explicatii='Somaj '+rtrim(convert(char(6),@pSomaj))+' - permanenti '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditSomajPerm, @LMSomajPerm, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMSomajPerm, '', '', 0

			Set @ContDebitor=rtrim(@DebitSomajOcaz)+rtrim(@AnActivDeb)
			set @Explicatii='Somaj '+rtrim(convert(char(6),@pSomaj))+' - ocazionali '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditSomajOcaz, @LMSomajOcaz, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMSomajOcaz, '', '', 0

			Set @ContDebitor=rtrim(@DebitFondGar)+rtrim(@AnActivDeb)
			set @Explicatii='Fond de garantare '+rtrim(convert(char(6),@pFondGar))+' - '+rtrim(@gLm)
			exec scriuNCsalarii @DataS, @ContDebitor, @CreditFondGar, @LMFondGar, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, '', '', @AnLMFondGar, '', '', 0
		End
		Set @gLm=@Lm
		set @gActivitate=@Activitate
	End
	close CasLM
	Deallocate CasLM
End

/*
	exec GenNCCheltLMBug '02/01/2011', '02/28/2011', '', 1, 309014
*/
