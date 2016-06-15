/* operatie pt. generare NC pt. cheltuieli salarii pe locuri de munca si comenzi */
Create procedure GenNCCheltLMCom
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @MarcaBrut char(9), @LmBrut char(9), @Continuare int output, @NrPozitie int output, @ActivitateBrut varchar(20), 
	@TCheltLMPerm decimal(10,2) output, @TCheltLMOcazO decimal(10,2) output, @TCheltLMOcazP decimal(10,2) output, @TCMUnitateLM decimal(10,2) output,
	@TAcordLM decimal(10,2), @TRegieLM decimal(10,2), @TIndOreSuplLM decimal(10,2), @TSporuriLM decimal(10,2), @TNelucratLM decimal(10,2), 
	@TCorectiiLM decimal(10,2), @TVenitLM decimal(10,2), @TVenitRealizatLM decimal(10,2), @TValRealizataMarca decimal(10,2) output, @NumarDoc char(8)
As
Begin try
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @Sub char(9), @SalComenzi int, @STOUG28 int, @PontajZilnic int, 
	@AcordGLTesaAcord int, @RealizGLNormaTimp int, @NCAnActiv int, @NCAnActivCtChelt int, 
	@RepManIndCom int, @RepIndCMUnitCom int, @RepManIndComTL int, @NumaiPontajeAcord int, 
	@RepAsigUnitCom int, @CheltSalComp int, @NCConsAdmGrpMP int, @Pasmatex int, @Somesana int, @Drumor int, 
	@Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), 
	@gLm char(9), @gComanda char(20), 
-- variabile pt. scriere NC
	@An641TipAc int, @Cont641Dif varchar(20), @Cont641AcGl varchar(20), @Cont641AcInd varchar(20), 
	@DebitCheltPerm varchar(20), @CreditCheltPerm varchar(20), @AnLMCheltPerm int, 
	@DebitCheltOcazO varchar(20), @CreditCheltOcazO varchar(20), @AnLMCheltOcazO int, @AtribCreditOcazO int, 
	@DebitCheltOcazP varchar(20), @CreditCheltOcazP varchar(20), @AnLMCheltOcazP int, @AtribCreditOcazP int, 
	@AnActivDeb char(10), @AnActivCre char(10), 
-- variabile din fetch
	@Marca char(6), @LM char(9), @NumarDocRC char(20), @Data datetime, @Comanda char(20), 
	@Cantitate decimal(10,3), @Tarif_unitar decimal(10,5), @Norma_de_timp decimal(12,6), 
	@Valoare_manopera decimal(10,2), @OreRealizateAcord decimal(10,2), @CoefAcord decimal(10,6), 
	@RealizatRegie decimal(10), @RealizatAcord decimal(10), 
	@IndOreSupl1 decimal(10), @IndOreSupl2 decimal(10), @IndOreSupl3 decimal(10), @IndOreSupl4 decimal(10), 
	@IndOreSpor100 decimal(10), @IndOreNoapte decimal(10), 
	@IndIT decimal(10), @IndObl decimal(10), @IndCO decimal(10), @IndIT2 decimal(10), 
	@IndCMUnitate decimal(10), @IndCMFnuass decimal(10), @CMCas decimal(10), @CMUnitate decimal(10), 
	@CO decimal(10), @Restituiri decimal(10), @Diminuari decimal(10), @SumaImpozabila decimal(10), 
	@Premiu decimal(10), @Diurna decimal(10), @ConsAdmin decimal(10), @SpSalarRealizat decimal(10), @SumaImpSep decimal(10), 
	@SporVechime decimal(10), @SporNoapte decimal(10), @SporSistPrg decimal(10), @SporFctSupl decimal(10), 
	@SporSpecific decimal(10), @SporCond1 decimal(10), @SporCond2 decimal(10), @SporCond3 decimal(10), 
	@SporCond4 decimal(10), @SporCond5 decimal(10), @SporCond6 decimal(10), 
	@VenitTotalBrut decimal(10), @IndCMFaambp decimal(10), @ValRealizataMarca decimal(10,2), @GrupaMIP char(1), @TipColab char(3), 
	@ValoarePozStd decimal(10,2), @ValoarePoz decimal(10,2), @ValIndCMUnitPoz decimal(10,2), @ManopDirPoz decimal(10,2), @IndOreSuplMLM decimal(10,2), 
	@SporuriMLM decimal(10,2), @VenitNelucratMLM decimal(10,2), @CorectiiMLM decimal(10,2), 
	@RegiePoz decimal(10,2), @IndOreSuplPoz decimal(10,2), @SporuriPoz decimal(10,2), 
	@VenitNelucratPoz decimal(10,2), @CorectiiPoz decimal(10,2), @AvMatImpoz decimal(10,2), 
	@ValRealizataCom decimal(10,2), @TRealizat decimal(10,2), @TCheltLMPermNerep decimal(10,2), 
	@CheltManopDir decimal(10,2), @UltNrDocMLM varchar(20), 
--variabile pt. totaluri pe LM si comanda
	@ValLMComPerm decimal(10,2), @ValLMComOcazO decimal(10,2), @ValLMComOcazP decimal(10,2), 
	@gfetch int

	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @STOUG28=dbo.iauParLN(@dataSus,'PS','@STOUG28')
	select 
		@Sub=max(case when Parametru='SUBPRO' then Val_alfanumerica else '' end),
		@SalComenzi=max(case when Parametru='SALCOM' then Val_logica else 0 end),
		@PontajZilnic=max(case when Parametru='PONTZILN' then Val_logica else 0 end),
		@AcordGLTesaAcord=max(case when Parametru='ACGLOTESA' then Val_logica else 0 end),
		@RealizGLNormaTimp=max(case when Parametru='RZANORMT' then Val_logica else 0 end),
		@NCAnActiv=max(case when Parametru='N-C-A-ACT' then Val_logica else 0 end),
		@NCAnActivCtChelt=max(case when Parametru='N-C-A-ACT' then Val_alfanumerica else 0 end),
		@RepManIndCom=max(case when Parametru='NC-MI-COM' then Val_logica else 0 end),
		@RepIndCMUnitCom=max(case when Parametru='NC-CM-COM' then Val_logica else 0 end),
		@RepManIndComTL=max(case when Parametru='NC-MC-TLC' then Val_logica else 0 end),
		@NumaiPontajeAcord=max(case when Parametru='NC-MC-PA' then Val_logica else 0 end),
		@RepAsigUnitCom=max(case when Parametru='NC-AU-COM' then Val_logica else 0 end),
		@CheltSalComp=max(case when Parametru='NC-CH-CMP' then Val_logica else 0 end),
		@NCConsAdmGrpMP=max(case when Parametru='NC-ADM-GP' then Val_logica else 0 end),
		@An641TipAc=max(case when Parametru='NC-CCH-TM' then Val_logica else 0 end),
		@Cont641Dif=max(case when Parametru='NC-CCH-TM' then Val_alfanumerica else '' end),
		@Cont641AcGl=max(case when Parametru='NC-CCH-AG' then Val_alfanumerica else '' end),
		@Cont641AcInd=max(case when Parametru='NC-CCH-AI' then Val_alfanumerica else '' end), 
		@DebitCheltPerm=max(case when Parametru='N-C-SAL1D' then Val_alfanumerica else '' end),
		@AnLMCheltPerm=max(case when Parametru='N-C-SAL1D' then Val_logica else 0 end),
		@CreditCheltPerm=max(case when Parametru='N-C-SAL1C' then Val_alfanumerica else '' end),
		@DebitCheltOcazO=max(case when Parametru='N-C-SAL2D' then Val_alfanumerica else '' end),
		@AnLMCheltOcazO=max(case when Parametru='N-C-SAL2D' then Val_logica else 0 end),
		@CreditCheltOcazO=max(case when Parametru='N-C-SAL2C' then Val_alfanumerica else '' end),
		@DebitCheltOcazP=max(case when Parametru='N-C-SAL3D' then Val_alfanumerica else '' end),
		@AnLMCheltOcazP=max(case when Parametru='N-C-SAL3D' then Val_logica else 0 end),
		@CreditCheltOcazP=max(case when Parametru='N-C-SAL3C' then Val_alfanumerica else '' end),
		@Pasmatex=max(case when Parametru='PASMATEX' then Val_logica else 0 end),
		@Somesana=max(case when Parametru='SOMESANA' then Val_logica else 0 end),
		@Drumor=max(case when Parametru='DRUMOR' then Val_logica else 0 end)
	from par 
	where tip_parametru='GE' and parametru in ('SUBPRO')
		or tip_parametru='PS' and parametru in ('SALCOM','PONTZILN','ACGLOTESA','RZANORMT','N-C-A-ACT','NC-MI-COM','NC-CM-COM','NC-MC-TLC','NC-MC-PA','NC-AU-COM','NC-CH-CMP','NC-ADM-GP',
			'NC-CCH-TM','NC-CCH-AG','NC-CCH-AI','N-C-SAL1D','N-C-SAL1C','N-C-SAL2D','N-C-SAL2C','N-C-SAL3D','N-C-SAL3C')
		or tip_parametru='SP' and parametru in ('PASMATEX','SOMESANA','DRUMOR')

	select @AtribCreditOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazO
	select @AtribCreditOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazP

	declare CheltLMCom cursor for
	select a.Marca, a.Loc_de_munca, a.Numar_document, a.Data, a.Comanda, a.Cantitate, a.Tarif_unitar, a.Norma_de_timp, 
	isnull(r.Valoare_manopera,0), isnull(r.Ore_realizate_in_acord,0), isnull(r.Coeficient_de_acord,0), isnull(b.Realizat__regie,0), isnull(b.Realizat_acord,0), 
	isnull(b.Indemnizatie_ore_supl_1,0), isnull(b.Indemnizatie_ore_supl_2,0), isnull(b.Indemnizatie_ore_supl_3,0), isnull(b.Indemnizatie_ore_supl_4,0), 
	isnull(b.Indemnizatie_ore_spor_100,0), isnull(b.Ind_ore_de_noapte,0), isnull(b.Ind_intrerupere_tehnologica,0), isnull(b.Ind_obligatii_cetatenesti,0), 
	isnull(b.Ind_concediu_de_odihna,0), isnull(b.Ind_invoiri,0), isnull(b.Ind_c_medical_unitate,0), isnull(b.Ind_c_medical_CAS,0), isnull(b.CMCAS,0), isnull(b.CMunitate,0), 
	isnull(b.CO,0), isnull(b.Restituiri,0), isnull(b.Diminuari,0), isnull(b.Suma_impozabila,0), 
	isnull(b.Premiu,0), isnull(b.Diurna,0), isnull(b.Cons_admin,0), isnull(b.Sp_salar_realizat,0), isnull(b.Suma_imp_separat,0), 
	isnull(b.Spor_vechime,0), isnull(b.Spor_de_noapte,0), isnull(b.Spor_sistematic_peste_program,0), isnull(b.Spor_de_functie_suplimentara,0), 
	isnull(b.Spor_specific,0), isnull(b.Spor_cond_1,0), isnull(b.Spor_cond_2,0), isnull(b.Spor_cond_3,0), isnull(b.Spor_cond_4,0), isnull(b.Spor_cond_5,0), isnull(b.Spor_cond_6,0), 
	isnull(b.Venit_total,0), isnull(b.Spor_cond_9,0), 
	(case when a.Marca<>'' and (@Drumor=1 or @RepManIndCom=1 or @RepManIndComTL=1) then isnull((select sum(round(r1.Cantitate*r1.Tarif_unitar,2))
		from realcom r1
			left outer join brut b1 on b1.Data=@dataSus and b1.Marca=r1.Marca and b1.Loc_de_munca=r1.Loc_de_munca
		where r1.Data between @dataJos and @dataSus and r1.Marca=a.Marca and (a.Marca<>'' and (@Pasmatex=1 or @RepManIndCom=1 or @RepManIndComTL=1) and r1.Loc_de_munca=@LmBrut)),0) else 0 end), 
	isnull(i.Grupa_de_munca,'N') as Grupa_de_munca, isnull(i.Tip_colab,'N') as tip_colab, 
	isnull((select top 1 r1.Numar_document 
		from realcom r1
			where @Salcomenzi=1 and r1.Data between @dataJos and @dataSus and r1.Marca=a.Marca and a.Marca<>'' and r1.Loc_de_munca=a.loc_de_munca 
		order by r1.Data desc, r1.Numar_document desc),'') as UltNrDocMLM, isnull(nullif(ai.Suma_neta,0),isnull(ai.Suma_corectie,0)) as AvMatImpoz
	from realcom a 
		left outer join reallmun r on r.Data=@dataSus and r.Loc_de_munca=a.Loc_de_munca
		left outer join #brut b on b.data=@dataSus and b.Marca=a.Marca and (b.Loc_de_munca=a.Loc_de_munca)
		left outer join istpers i on i.data=@dataSus and i.Marca=a.Marca
		left outer join personal p on p.marca=a.marca
		left outer join infopers f on f.marca=a.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'AI', '', '', 1) ai on ai.Data=a.data and ai.Marca=a.Marca and ai.Loc_de_munca=a.Loc_de_munca
	where a.data between @dataJos and @dataSus and (a.Loc_de_munca=@LmBrut) 
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
		and (not(@pMarca<>'' or @Pasmatex=1) or @Pasmatex=1 and a.Marca=@MarcaBrut or @Pasmatex=0 and a.Marca=@pMarca) 
		and (@NCAnActiv=0 or a.marca='' or p.Activitate=@ActivitateBrut)
	order by a.Loc_de_munca, a.Comanda, a.Marca

	open CheltLMCom
	fetch next from CheltLMCom into @Marca, @LM, @NumarDocRC, @Data, @Comanda, @Cantitate, @Tarif_unitar, @Norma_de_timp, 
		@Valoare_manopera, @OreRealizateAcord, @CoefAcord, @RealizatRegie, @RealizatAcord, 
		@IndOreSupl1, @IndOreSupl2, @IndOreSupl3, @IndOreSupl4, @IndOreSpor100, @IndOreNoapte, 
		@IndIT, @IndObl, @IndCO, @IndIT2, @IndCMUnitate, @IndCMFnuass, @CMCas, @CMUnitate, 
		@CO, @Restituiri, @Diminuari, @SumaImpozabila, @Premiu, @Diurna, @ConsAdmin, @SpSalarRealizat, @SumaImpSep, 
		@SporVechime, @SporNoapte, @SporSistPrg, @SporFctSupl, @SporSpecific, @SporCond1, @SporCond2, @SporCond3, @SporCond4, @SporCond5, @SporCond6, 
		@VenitTotalBrut, @IndCMFaambp, @ValRealizataMarca, @GrupaMIP, @TipColab, @UltNrDocMLM, @AvMatImpoz
	set @TCheltLMPermNerep=0
	if @CheltSalComp=1
		set @TCheltLMPermNerep=@TCheltLMPerm
	set @gfetch=@@fetch_status
	set @gLm=@Lm
	set @gComanda=@Comanda
	While @gfetch = 0 
	Begin
		select @ValLMComPerm=0, @ValLMComOcazO=0, @ValLMComOcazP=0, @ValIndCMUnitPoz=0
		while @Comanda = @gComanda and @gfetch = 0
		Begin
			select @IndOreSuplMLM=@IndOresupl1+@IndOresupl2+@IndOresupl3+@IndOresupl4+@IndOreSpor100+@IndOreNoapte, 
				@SporuriMLM=@SporVechime+@SporSpecific+@SporNoapte+@SporSistPrg+@SporFctSupl+
				@SporCond1+@SporCond2+@SporCond3+@SporCond4+@SporCond5+@SporCond6+@Premiu+@SpSalarRealizat,
				@VenitNelucratMLM=@IndObl+@IndCO+@IndIT+@IndIT2, 
				@CorectiiMLM=@CO+@Restituiri-@Diminuari+@SumaImpozabila+@Diurna+@ConsAdmin+@SumaImpSep

			set @AnActivDeb=(case when @NCAnActiv=1 then '.'+rtrim(@ActivitateBrut) else '' end)
			set @AnActivCre=(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(@ActivitateBrut) else '' end)
			set @ValoarePozStd=(case when @RealizGLNormaTimp=1 and @Marca='' 
			then @Cantitate*@Norma_de_timp*(@Valoare_manopera/@OreRealizateAcord) else @Cantitate*@Tarif_unitar end)
			set @ValoarePoz=@ValoarePozStd
			if @Marca='' and (@RepManIndCom=1 or @RepManIndComTL=1)
				set @ValoarePoz=@ValoarePoz*(case when @TVenitRealizatLM=0 then 1 else @TVenitLM/@TVenitRealizatLM end)

			if @Marca<>'' and (@DrumOr=1 or @RepManIndCom=1 or @RepManIndComTL=1)
			Begin
				set @TValRealizataMarca=@ValRealizataMarca
				select @ValIndCMUnitPoz=(case when @ValRealizataMarca=0 then (case when @SalComenzi=1 and @PontajZilnic=0 then @IndCMUnitate+@CMUnitate else 0 end)
					else @ValoarePoz*(@IndCMUnitate+@CMUnitate)/@ValRealizataMarca end) where @RepIndCMUnitCom=1
				set @ValoarePoz=@ValoarePoz*(case when @ValRealizataMarca=0 then 1 
					else (@VenitTotalBrut-(case when @RepIndCMUnitCom=0 then @IndCMUnitate+@CMUnitate else 0 end)-(@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz)
					-(case when @RepManIndComTL=1 then @VenitNelucratMLM+@CorectiiMLM else 0 end))/@ValRealizataMarca end)

				if @SalComenzi=1 and @PontajZilnic=0 and @RepManIndCom=1 and @ValoarePoz=0 and @ValRealizataMarca=0 and @NumarDocRC=@UltNrDocMLM
					set @ValoarePoz=@VenitTotalBrut-(case when @RepIndCMUnitCom=0 then @IndCMUnitate+@CMUnitate else 0 end)-(@IndCMFnuass+@CMCas+@IndCMFaambp+@AvMatImpoz)
				select @TCMUnitateLM=@TCMUnitateLM-@ValIndCMUnitPoz where @RepIndCMUnitCom=1
			End
			if @GrupaMIP not in ('O','P')
			Begin
				set @ValLMComPerm=@ValLMComPerm+@ValoarePoz
				set @TCheltLMPerm=@TCheltLMPerm-@ValoarePoz+@ValIndCMUnitPoz
			End	
			if @GrupaMIP='O' or @GrupaMIP='P' and @TipColab in ('AS5','AS2') and @NCConsAdmGrpMP=0
			Begin
				set @ValLMComOcazO=@ValLMComOcazO+@ValoarePoz
				set @TCheltLMOcazO=@TCheltLMOcazO-@ValoarePoz
			End	
			if @GrupaMIP='P' and (not(@TipColab in ('AS5','AS2')) or @NCConsAdmGrpMP=1 or @SalComenzi=1 and @ValIndCMUnitPoz<>0)
			Begin
				set @ValLMComOcazP=@ValLMComOcazP+@ValoarePoz
				set @TCheltLMOcazP=@TCheltLMOcazP-@ValoarePoz+@ValIndCMUnitPoz
			End	

			if @Continuare=1 and @An641TipAc=1
			Begin
				Set @ContDebitor=(case when @An641TipAc=1 then (case when @Marca='' then rtrim(@Cont641AcGl) else rtrim(@Cont641AcInd) end)
				else rtrim(@DebitCheltPerm)+rtrim(@AnActivDeb) end)
				Set @ContCreditor=(case when @GrupaMIP not in ('O','P') then rtrim(@CreditCheltPerm) else rtrim(@CreditCheltOcazO) end)+rtrim(@AnActivCre)
				set @Explicatii='Manopera directa - '+rtrim(@Lm)+' '+rtrim(@Comanda)

				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValoarePoz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @Lm, @Comanda, '', @AnLMCheltPerm, '', '', 0
			End	

--	pt. cazul generarii notei contabile pe comenzi la salariatii ocazionali
			if @Continuare=1 and @AtribCreditOcazO=1 and (@GrupaMIP='O' or @GrupaMIP='P' and @TipColab in ('AS5','AS2')) 
			Begin
				set @ContDebitor=rtrim(@DebitCheltOcazO)+rtrim(@AnActivDeb)
				set @ContCreditor=rtrim(@CreditCheltOcazO)+rtrim(@AnActivCre)			
				set @Explicatii=left('Manopera directa - marca '+rtrim(@Marca)+' '+rtrim(@Lm)+' '+rtrim(@Comanda),50)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValoarePoz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @Lm, @Comanda, '', @AnLMCheltOcazO, @Marca, '', 0
			End	
			if @Continuare=1 and @AtribCreditOcazP=1 and @GrupaMIP='P' and not(@TipColab in ('AS5','AS2')) 
			Begin
				set @ContDebitor=rtrim(@DebitCheltOcazP)+rtrim(@AnActivDeb)
				set @ContCreditor=rtrim(@CreditCheltOcazP)+rtrim(@AnActivCre)
				set @Explicatii=left('Manopera directa - marca '+rtrim(@Marca)+' '+rtrim(@Lm)+' '+rtrim(@Comanda),50)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValoarePoz, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @Lm, @Comanda, '', @AnLMCheltOcazP, @Marca, '', 0
			End	

--	pt. cazul generarii notei contabile detaliata pe numar document
			if 1=0
			Begin
				Set @ContDebitor=(case when @GrupaMIP not in ('O','P') then rtrim(@DebitCheltPerm) else rtrim(@DebitCheltOcazO) end)+rtrim(@AnActivDeb)
				Set @ContCreditor=(case when @GrupaMIP not in ('O','P') then rtrim(@CreditCheltPerm) else rtrim(@CreditCheltOcazO) end)+rtrim(@AnActivCre)
				set @Explicatii='Manopera directa - '+rtrim(@Lm)+' '+rtrim(@Comanda)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValoarePoz, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @Lm, @Comanda, '', @AnLMCheltPerm, '', '', 0
			End
--	pentru repartizare cheltuieli pe componente (Specific Remarul)
			if @CheltSalComp=1
			Begin
				set @ManopDirPoz=@ValoarePozStd
				set @RegiePoz=@ManopDirPoz*(case when @Marca<>'' then (case when @ValRealizataMarca=0 then 1 else @RealizatRegie/@ValRealizataMarca end)
					else (case when @TVenitRealizatLM=0 then 1 else @TRegieLM/@TVenitRealizatLM end) end)
				set @IndOreSuplPoz=@ManopDirPoz*(case when @Marca<>'' then (case when @ValRealizataMarca=0 then 1 else @IndOreSuplMLM/@ValRealizataMarca end)
					else (case when @TVenitRealizatLM=0 then 1 else @TIndOreSuplLM/@TVenitRealizatLM end) end)
				set @SporuriPoz=@ManopDirPoz*(case when @Marca<>'' then (case when @ValRealizataMarca=0 then 1 else @SporuriMLM/@ValRealizataMarca end)
					else (case when @TVenitRealizatLM=0 then 1 else @TSporuriLM/@TVenitRealizatLM end) end)
				set @VenitNelucratPoz=@ManopDirPoz*(case when @Marca<>'' then (case when @ValRealizataMarca=0 then 1 else @VenitNelucratMLM/@ValRealizataMarca end)
					else (case when @TVenitRealizatLM=0 then 1 else @TNelucratLM/@TVenitRealizatLM end) end)
				set @CorectiiPoz=@ManopDirPoz*(case when @Marca<>'' then (case when @ValRealizataMarca=0 then 1 else @CorectiiMLM/@ValRealizataMarca end)
					else (case when @TVenitRealizatLM=0 then 1 else @TCorectiiLM/@TVenitRealizatLM end) end)
				Set @ContDebitor=(case when @An641TipAc=1 then (case when @Marca='' then rtrim(@Cont641AcGl) else rtrim(@Cont641AcInd) end)
					else rtrim(@DebitCheltPerm)+rtrim(@AnActivDeb) end)
				
				set @CheltManopDir=@ManopDirPoz+@ManopDirPoz*(case when @Marca<>'' then (case when @ValRealizataMarca=0 then 1 else (@RealizatAcord-@ValRealizataMarca)/@ValRealizataMarca end)
					else (case when @TVenitRealizatLM=0 then 1 else (@TAcordLM-@TVenitRealizatLM)/@TVenitRealizatLM end) end)

				exec scriuCheltComp @Data, @Lm, @Comanda, @ContDebitor, 'Manopera directa', @CheltManopDir
				exec scriuCheltComp @Data, @Lm, @Comanda, @ContDebitor, 'Regie', @RegiePoz
				exec scriuCheltComp @Data, @Lm, @Comanda, @ContDebitor, 'Ore suplimentare', @IndOreSuplPoz
				exec scriuCheltComp @Data, @Lm, @Comanda, @ContDebitor, 'Sporuri', @SporuriPoz
				Set @ContDebitor=(case when @An641TipAc=1 then rtrim(@Cont641Dif) else rtrim(@DebitCheltPerm)+rtrim(@AnActivDeb) end)
				exec scriuCheltComp @Data, @Lm, @Comanda, @ContDebitor, 'Timp nelucrat (CO, OBL, INTR)', @VenitNelucratPoz
				exec scriuCheltComp @Data, @Lm, @Comanda, @ContDebitor, 'Corectii', @CorectiiPoz
			End
			fetch next from CheltLMCom into @Marca, @LM, @NumarDocRC, @Data, @Comanda, @Cantitate, @Tarif_unitar, @Norma_de_timp, 
				@Valoare_manopera, @OreRealizateAcord, @CoefAcord, @RealizatRegie, @RealizatAcord, 
				@IndOreSupl1, @IndOreSupl2, @IndOreSupl3, @IndOreSupl4, @IndOreSpor100, @IndOreNoapte, 
				@IndIT, @IndObl, @IndCO, @IndIT2, @IndCMUnitate, @IndCMFnuass, @CMCas, @CMUnitate, 
				@CO, @Restituiri, @Diminuari, @SumaImpozabila, @Premiu, @Diurna, @ConsAdmin, @SpSalarRealizat, @SumaImpSep, 
				@SporVechime, @SporNoapte, @SporSistPrg, @SporFctSupl, @SporSpecific, @SporCond1, @SporCond2, @SporCond3, @SporCond4, @SporCond5, @SporCond6, 
				@VenitTotalBrut, @IndCMFaambp, @ValRealizataMarca, @GrupaMIP, @TipColab, @UltNrDocMLM, @AvMatImpoz
			set @gfetch=@@fetch_status
		End

--	procedura pt. asigurari pe lm si com
		if @Continuare=1 and @An641TipAc=0
		Begin
			Set @ContDebitor=rtrim(@DebitCheltPerm)+rtrim(@AnActivDeb)
			Set @ContCreditor=rtrim(@CreditCheltPerm)+rtrim(@AnActivCre)
			set @Explicatii='Manopera directa - '+rtrim(@gLm)+' '+rtrim(@gComanda)
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValLMComPerm, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', @AnLMCheltPerm, '', '', 0

			if @AtribCreditOcazO<>1
			begin 
				Set @ContDebitor=rtrim(@DebitCheltOcazO)+rtrim(@AnActivDeb)
				Set @ContCreditor=rtrim(@CreditCheltOcazO)+rtrim(@AnActivCre)
				set @Explicatii='Manopera directa - '+rtrim(@gLm)+' '+rtrim(@gComanda)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValLMComOcazO, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', @AnLMCheltOcazO, '', '', 0
			end

			if @AtribCreditOcazP<>1
			Begin
				Set @ContDebitor=rtrim(@DebitCheltOcazP)+rtrim(@AnActivDeb)
				Set @ContCreditor=rtrim(@CreditCheltOcazP)+rtrim(@AnActivCre)
				set @Explicatii='Manopera directa - '+rtrim(@gLm)+' '+rtrim(@gComanda)
				exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @ValLMComOcazP, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', @AnLMCheltOcazP, '', '', 0
			End
		End
		set @gLm=@Lm
		set @gComanda=@Comanda
	End
	close CheltLMCom
	Deallocate CheltLMCom

	Set @ContDebitor=(case when @An641TipAc=1 then rtrim(@Cont641Dif) else rtrim(@DebitCheltPerm)+rtrim(@AnActivDeb) end)
	if @CheltSalComp=1 and @TCheltLMPermNerep<>0
		exec scriuCheltComp @dataSus, @LmBrut, '', @ContDebitor, 'Cheltuieli fara comanda', @TCheltLMPermNerep
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenNCCheltLMCom (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec GenNCCheltLMCom '02/01/2011', '02/28/2011', '', 1, 309014
*/
