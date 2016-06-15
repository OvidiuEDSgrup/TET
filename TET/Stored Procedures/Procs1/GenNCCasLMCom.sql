/* operatie pt. generare NC pt. asigurari angajator pe locuri de munca si comenzi */
Create procedure GenNCCasLMCom
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @LmBrut char(9), @MarcaBrut char(6), @ActivitateBrut varchar(20), 
	@Continuare int output, @NrPozitie int output, @LMVenit decimal(10,2), @LMVenitSomaj decimal(10,2), @LMVenitITM decimal(10,2), @LMVenitRealiz decimal(10,2), 
	@LMCasPerm decimal(10,2) output, @LMCasOcaz decimal(10,2) output, @LMCassPerm decimal(10,2) output, @LMCassOcaz decimal(10,2) output, @LMCassPDafora decimal(10,2) output, 
	@LMFaambpPerm decimal(10,2) output, @LMFaambpOcaz decimal(10,2) output, @LMItm decimal(10,2) output, 
	@LMSomajPerm decimal(10,2) output, @LMSomajOcaz decimal(10,2) output, @LMCCIPerm decimal(10,2) output, @LMCCIOcaz decimal(10,2) output, @LMFondGar decimal(10,2) output, 
	@LMSubvSomaj decimal(10,2) output, @LMScutireSomaj decimal(10,2) output, @NumarDoc char(8)
As
Begin try
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @Sub char(9), @SalComenzi int, @PontajZilnic int, @STOUG28 int, @NuITMColab int, @NuITMPens int, 
	@AcordGLTesaAcord int, @RealizGLNormaTimp int, @NuCAS_H int, 
	@pCasIndiv decimal(5,2), @pCasCN decimal(5,2), @pCasCD decimal(5,2), @pCasCS decimal(5,2), @pCCI decimal(5,2), @pCass decimal(5,2), @pFaambp decimal(7,3), 
	@CalcITM int, @pITM decimal(5,2), @pSomaj decimal(5,2), @pFondGar decimal(5,2), @CoefCCI float, 
	@NCIndBug int, @NCAnActiv int, @NCAnActivCtChelt int, @RepManIndCom int, @RepIndCMUnitCom int, 
	@RepManIndComTL int, @NumaiPontajeAcord int, @RepAsigUnitCom int, @NCSubvSomaj int, @Pasmatex int, @Grasetto int, @Reva int, @DrumOr int,
	@Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), 
	@DenSuma char(30), @gLm char(9), @gMarca char(6), @IndBug char(20), @gComanda char(20), @gVenitRealizatLm decimal(10,2), 

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
	@Data datetime, @Marca char(6), @Lm char(9), @NumarDocRC char(20), @UltNrDocMLM varchar(20), @Comanda char(20), 
	@Cantitate decimal(10,3), @Tarif_unitar decimal(12,5), @Norma_de_timp decimal(12,6), 
	@GrupaMPontaj char(1), @Valoare_manopera decimal(10,2), @Ore_realizate_in_acord decimal(10,2), 
	@IndCMUnitate decimal(10), @CMUnitate decimal(10), @IndCMCAS decimal(10), @CMCAS decimal(10), @IndCMFaambp decimal(10), 
	@SomajTehnic decimal(10), @Venit_total decimal(10), @Spor_vechime decimal(10), @Spor_specific decimal(10), @CasaSanatate char(30), 
	@ValRealizataMarca decimal(10,2), @VenitNelucratPoz decimal(10,2), @VenitCorectiiPoz decimal(10,2), 
	@Pensionar int, @GrupaM char(1), @TipColab char(3), @Somaj_1 int, @SubvSomaj decimal(10), @ScutireSomaj decimal(10), 
	@BazaCasCM decimal(10), @BazaFaambpCM decimal(10), @SomajUnitate decimal(7,2), @FondGar decimal(7,2), 
-- variabile pt. valori la nivel de pozitie pe comanda
	@CASCom decimal(10,2), @CCICom decimal(10,2), @CassCom decimal(10,2), @FaambpCom decimal(10,2), @ITMCom decimal(10,2), 
	@FondGarCom decimal(10,2), @SomajCom decimal(10,2), @SubvSomajCom decimal(10,2), @ScutireSomajCom decimal(10,2), 
	@gValoarePoz decimal(10,2), @ValoarePoz decimal(10,2), @ValPozCasCM decimal(10,2), @ValPozFaambpCM decimal(10,2), 
	@ValoarePozSomaj decimal(10,2), @ValoarePozITM decimal(10,2), 
	@ValoarePoz2_CMStat decimal(10,2), @ValoarePozSomaj2 decimal(10,2), @ValoarePozITM2 decimal(10,2), 
	@ValoarePonderata float, @ValoarePonderata2 float, 
--variabile pt. totaluri pe LM si comanda
	@LMCasCom decimal(10,2), @LMCassCom decimal(10,2), @LMCassComDafora decimal(10,2), 
	@LMFaambpCom decimal(10,2), @LMITMCom decimal(10,2), 
	@LMSomajCom decimal(10,2), @LMCCICom decimal(10,2), @LMFondGarCom decimal(10,2), 
	@LMSubvSomajCom decimal(10,2), @LMScutireSomajCOm decimal(10,2), 
	@gfetch int

	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @SalComenzi=dbo.iauParL('PS','SALCOM')
	set @STOUG28=dbo.iauParLN(@dataSus,'PS','STOUG28')
	set @PontajZilnic=dbo.iauParL('PS','PONTZILN')
	set @NuITMColab=dbo.iauParL('PS','NCALPCMC')
	set @NuITMPens=dbo.iauParL('PS','NCALPCMPE')
	set @AcordGLTesaAcord=dbo.iauParL('PS','ACGLOTESA')
	set @RealizGLNormaTimp=dbo.iauParL('PS','RZANORMT')
	set @pCasIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pCasCN=dbo.iauParLN(@dataSus,'PS','CASGRUPA3')
	set @pCasCD=dbo.iauParLN(@dataSus,'PS','CASGRUPA2')
	set @pCasCS=dbo.iauParLN(@dataSus,'PS','CASGRUPA1')
	set @pCCI=dbo.iauParLN(@dataSus,'PS','COTACCI')
	set @pCass=dbo.iauParLN(@dataSus,'PS','CASSUNIT')
	set @pFaambp=dbo.iauParLN(@dataSus,'PS','0.5%ACCM')
	set @CalcITM=dbo.iauParL('PS','1%CAMERA')
	set @pITM=dbo.iauParLN(@dataSus,'PS','1%CAMERA')
	set @pSomaj=dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ')
	set @pFondGar=dbo.iauParLN(@dataSus,'PS','FONDGAR')
	set @CoefCCI=dbo.iauParN('PS','COEFCCI')
	set @CoefCCI=@CoefCCI/1000000
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')
	set @RepManIndCom=dbo.iauParL('PS','NC-MI-COM')
	set @RepIndCMUnitCom=dbo.iauParL('PS','NC-CM-COM')
	set @RepManIndComTL=dbo.iauParL('PS','NC-MC-TLC')
	set @NumaiPontajeAcord=dbo.iauParL('PS','NC-MC-PA')
	set @RepAsigUnitCom=dbo.iauParL('PS','NC-AU-COM')
	set @NCSubvSomaj=dbo.iauParL('PS','N-SUBVSJD')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @Grasetto=dbo.iauParL('SP','NCGRASS')
	set @Reva=dbo.iauParL('SP','REVA')

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

declare CasLMCom cursor for
select a.Data, a.Marca, a.Loc_de_munca, a.Numar_document, a.Comanda, a.Cantitate, a.Tarif_unitar, a.Norma_de_timp, 
isnull((select max(t.Grupa_de_munca) from pontaj t where t.data between @dataJos and @dataSus and t.Marca=a.Marca and t.Loc_de_munca=a.Loc_de_munca),'N'), 
isnull(r.Valoare_manopera,0), isnull(r.Ore_realizate_in_acord,0), isnull(b.Ind_c_medical_unitate,0), isnull(b.CMunitate,0), 
isnull(b.Ind_c_medical_CAS,0), isnull(b.CMCAS,0), isnull(b.Spor_cond_9,0), 
(case when @STOUG28=1 then isnull(b.Ind_invoiri,0) else 0 end), isnull(b.Venit_total,0), 
isnull(b.Spor_vechime,0), isnull(b.Spor_specific,0), isnull(p.Adresa,''), 
(case when a.Marca<>'' and (@DrumOr=1 or @RepManIndCom=1 or @RepManIndComTL=1) 
then isnull((select sum(round(r1.Cantitate*r1.Tarif_unitar+
(case when @Grasetto=1 then b1.Indemnizatie_ore_supl_1+b1.Indemnizatie_ore_supl_2+b1.Indemnizatie_ore_supl_3+b1.Indemnizatie_ore_supl_4 +b1.Spor_vechime+b1.Spor_specific+b1.Spor_cond_1+b1.Spor_cond_2 else 0 end),2))
from realcom r1
	left outer join brut b1 on b1.Data=@dataSus and b1.Marca=r1.Marca and b1.Loc_de_munca=r1.Loc_de_munca
where r1.Data between @dataJos and @dataSus and r1.Marca=a.Marca and (a.Marca<>'' and (@DrumOr=1 or @RepManIndCom=1 or @RepManIndComTL=1) and r1.Loc_de_munca=@LmBrut)),0) else 0 end), 
isnull((b.ind_concediu_de_odihna+b.ind_intrerupere_tehnologica+ind_obligatii_cetatenesti+b.ind_invoiri),0), 
isnull((b.CO+b.Restituiri+b.Diminuari+b.Suma_impozabila+b.Premiu+b.Diurna+b.Cons_admin+ b.Sp_salar_realizat+b.Suma_imp_separat),0), 
isnull(p.Coef_invalid,0), isnull(p1.Grupa_de_munca,''), isnull(p1.Tip_colab,''), isnull(p.Somaj_1,1), isnull(n.Chelt_prof,0), isnull(s.Scutire_art80,0)+isnull(s.Scutire_art85,0),
isnull(n1.Baza_CAS_cond_norm+n1.Baza_CAS_cond_deoseb+n1.Baza_CAS_cond_spec,0), isnull(n1.Asig_sanatate_din_CAS,0), isnull(n.Somaj_5,0), isnull(n1.Somaj_5,0), 
isnull((select top 1 r1.Numar_document from realcom r1
where @Salcomenzi=1 and r1.Data between @dataJos and @dataSus and r1.Marca=a.Marca and a.Marca<>'' and r1.Loc_de_munca=a.loc_de_munca 
order by r1.Data desc, r1.Numar_document desc),'') as UltNrDocMLM
from realcom a 
	left outer join personal p on p.Marca=a.Marca
	left outer join istpers p1 on p1.Data=@dataSus and p1.Marca=a.Marca
	left outer join reallmun r on r.Data=@dataSus and r.Loc_de_munca=a.Loc_de_munca
	left outer join #brut b on b.data=@dataSus and b.Marca=a.Marca and b.Loc_de_munca=a.Loc_de_munca
	left outer join infopers f on f.marca=a.marca
	left outer join #net n on n.Data=@dataSus and n.Marca=a.Marca
	left outer join #net n1 on n1.Data=@dataJos and n1.Marca=a.Marca
	left outer join dbo.fScutiriSomaj (@dataJos, @dataSus, '', 'ZZZ', '', 'ZZZ') s on s.Data=@dataSus and s.Marca=a.Marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.loc_de_munca
where a.data between @dataJos and @dataSus and a.Loc_de_munca=@LmBrut
	and (not(@pMarca<>'') or a.Marca=@pMarca) and (@NCAnActiv=0 or a.marca='' or p.Activitate=@ActivitateBrut)
	and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
order by a.Loc_de_munca, a.Comanda, a.Marca

open CasLMCom
fetch next from CasLMCom into @Data, @Marca, @Lm, @NumarDocRC, @Comanda, @Cantitate, @Tarif_unitar, @Norma_de_timp, 
	@GrupaMPontaj, @Valoare_manopera, @Ore_realizate_in_acord, @IndCMUnitate, @CMUnitate, @IndCMCAS, @CMCAS, @IndCMFaambp, 
	@SomajTehnic, @Venit_total, @Spor_vechime, @Spor_specific, @CasaSanatate, @ValRealizataMarca, 
	@VenitNelucratPoz, @VenitCorectiiPoz, @Pensionar, @GrupaM, @TipColab, @Somaj_1, 
	@SubvSomaj, @ScutireSomaj, @BazaCasCM, @BazaFaambpCM, @SomajUnitate, @FondGar, @UltNrDocMLM

set @gfetch=@@fetch_status
set @gMarca=@Marca
set @gLm=@Lm
set @gComanda=@Comanda
While @gfetch = 0 
Begin
	select @LMCasCom=0, @LMCassCom=0, @LMCassComDafora=0, @LMFaambpCom=0, @LMITMCom=0, 
	@LMSomajCom=0, @LMCCICom=0, @LMFondGarCom=0, @LMSubvSomajCom=0, @LMScutireSomajCom=0, 
	@ValPozCasCM=0, @ValPozFaambpCM=0
	while @Comanda = @gComanda and @gfetch = 0
	Begin
--		calcul contributii pe comanda 
		set @gValoarePoz=(case when @RealizGLNormaTimp=1 and @Marca='' 
		then @Cantitate*@Norma_de_timp*(@Valoare_manopera/(case when @Ore_realizate_in_acord=0 then 1 else @Ore_realizate_in_acord end)) else @Cantitate*@Tarif_unitar end)
		set @ValoarePoz=@gValoarePoz
		set @ValoarePozSomaj=@gValoarePoz
		set @ValoarePozITM=@gValoarePoz
		if @Marca='' and (@RepManIndCom=1 or @RepManIndComTL=1)
		Begin
			set @ValoarePoz=@ValoarePoz*(case when @LMVenitRealiz=0 then 1 else @LMVenit/@LMVenitRealiz end)
			set @ValoarePozSomaj=@ValoarePozSomaj*(case when @LMVenitRealiz=0 then 1 else @LMVenitSomaj/@LMVenitRealiz end)
			set @ValoarePozITM=@ValoarePozITM*(case when @LMVenitRealiz=0 then 1 else @LMVenitITM/@LMVenitRealiz end)
		End
		if @SalComenzi=1
			select @ValoarePoz2_CMStat=@ValoarePoz, @ValoarePozSomaj2=@ValoarePozSomaj, @ValoarePozITM2=@ValoarePozITM
		if @Marca<>'' and (@DrumOr=1 or @RepManIndCom=1 or @RepManIndComTL=1)
		Begin
			if @RepIndCMUnitCom=1
			Begin
				set @ValPozCasCM=(case when @ValRealizataMarca=0 then (case when @SalComenzi=1 and @PontajZilnic=0 then @BazaCasCM else 0 end) 
				else @ValoarePoz*@BazaCasCM/@ValRealizataMarca end)
				set @ValPozFaambpCM=(case when @ValRealizataMarca=0 then (case when @SalComenzi=1 and @PontajZilnic=0 then @BazaFaambpCM else 0 end) 
				else @ValoarePoz*@BazaFaambpCM/@ValRealizataMarca end)
			End	
			set @ValoarePonderata=(case when @ValRealizataMarca=0 then 1 else
			(@Venit_total-(case when @RepManIndCom=1 or @RepManIndComTL=1 then @IndCMUnitate+@CMUnitate+@IndCMCAS+@CMCAS+@IndCMFaambp else 0 end)
			-(case when @RepManIndComTL=1 then @VenitNelucratPoz+@VenitCorectiiPoz else 0 end)-@SomajTehnic)/@ValRealizataMarca end)
			set @ValoarePoz=@ValoarePoz*@ValoarePonderata
			set @ValoarePozSomaj=@ValoarePozSomaj*(case when @Pensionar=5 then 0 else @ValoarePonderata end)
			set @ValoarePozITM=@ValoarePozITM*@ValoarePonderata
			if @SalComenzi=1
			Begin
				set @ValoarePonderata2=(case when @ValRealizataMarca=0 then 1 else
				(@Venit_total-(case when @RepManIndCom=1 or @RepManIndComTL=1 then @IndCMCAS+@CMCAS+@IndCMFaambp else 0 end)
				-(case when @RepManIndComTL=1 then @VenitNelucratPoz+@VenitCorectiiPoz else 0 end)-@SomajTehnic)/@ValRealizataMarca end)
				set @ValoarePoz2_CMStat=@ValoarePoz2_CMStat*@ValoarePonderata2
				set @ValoarePozSomaj2=@ValoarePozSomaj2*(case when @Pensionar=5 then 0 else @ValoarePonderata2 end)
				set @ValoarePozITM2=@ValoarePozITM2*@ValoarePonderata2
			End
			if @SalComenzi=1 and @PontajZilnic=0 and @RepManIndCom=1 and @ValRealizataMarca=0 and @NumarDocRC=@UltNrDocMLM
			Begin
				select @ValoarePoz=@Venit_total-(@IndCMUnitate+@CMUnitate+@IndCMCAS+@CMCAS+@IndCMFaambp) where @ValoarePoz=0
				select @ValoarePoz2_CMStat=@Venit_total-(@IndCMCAS+@CMCAS+@IndCMFaambp) 
				where @ValoarePoz2_CMStat=0 and @TipColab not in ('DAC','CCC','ECT')
				select @ValoarePozSomaj2=@Venit_total-(@IndCMCAS+@CMCAS+@IndCMFaambp) 
				where @ValoarePozSomaj2=0 and @Pensionar<>5 and @TipColab not in ('DAC','CCC','ECT')
				select @ValoarePozITM2=@Venit_total-(@IndCMCAS+@CMCAS+@IndCMFaambp) where @ValoarePozITM2<>0
			End
		End
		if @SalComenzi=0
			select @ValoarePoz2_CMStat=@ValoarePoz, @ValoarePozSomaj2=@ValoarePozSomaj, @ValoarePozITM2=@ValoarePozITM

		if not(@GrupaM='O')
		Begin
			set @CASCom=round(@ValoarePoz*((case when @GrupaMPontaj='S' then @pCasCS when @GrupaMPontaj='D' then @pCasCD else @pCasCN end)-@pCasIndiv)/100,2)+
				round(@ValPozCasCM*((case when @GrupaMPontaj='S' then @pCasCS when @GrupaMPontaj='D' then @pCasCD else @pCasCN end)-@pCasIndiv)/100,0)
			set @LMCasCom=@LMCasCom+@CASCom
			select @LMCasPerm=@LMCasPerm-@CASCom where @GrupaM not in ('P')
			select @LMCasOcaz=@LMCasOcaz-@CASCom where @GrupaM in ('P')
			if not(@GrupaM='P' and @TipColab in ('AS2','AS4','AS5','AS6') and YEAR(@dataSus)>=2012)
			Begin
				set @FaambpCom=round(@ValoarePoz*@pFaambp/100,2)+round(@ValPozFaambpCM*@pFaambp/100,2)
				set @LMFaambpCom=@LMFaambpCom+@FaambpCom
				select @LMFaambpPerm=@LMFaambpPerm-@FaambpCom where @GrupaM not in ('P')
				select @LMFaambpOcaz=@LMFaambpOcaz-@FaambpCom where @GrupaM in ('P')
				if @SalComenzi=1 and abs(@LMFaambpPerm) between 0.01 and 0.02
					select @LMFaambpCom=@LMFaambpCom+@LMFaambpPerm, @LMFaambpPerm=0
			End	
		End
		if not(@GrupaM in ('O','P') and @TipColab in ('AS4','AS5','AS6','DAC','CCC','ECT'))
		Begin
			set @CCICom=round(@ValoarePoz2_CMStat*(case when @CoefCCI>0 and @CoefCCI<1 then @CoefCCI else 1 end)*@pCCI/100,2)
			set @LMCCICom=@LMCCICom+@CCICom
			set @LMCCIPerm=@LMCCIPerm-@CCICom
			if @SalComenzi=1 and abs(@LMCCIPerm) between 0.01 and 0.02
				select @LMCCICom=@LMCCICom+@LMCCIPerm, @LMCCIPerm=0
		End	
		set @CassCom=round(@ValoarePoz2_CMStat*@pCass/100,2)
		if @Reva=0 or @CasaSanatate='CNAS'
		Begin
			select @LMCassCom=@LMCassCom+@CassCom
			select @LMCassPerm=@LMCassPerm-@CassCom where not(@GrupaM in ('O','P'))
			if @SalComenzi=1 and abs(@LMCassPerm) between 0.01 and 0.02
				select @LMCassCom=@LMCassCom+@LMCassPerm, @LMCassPerm=0
			select @LMCassOcaz=@LMCassOcaz-@CassCom where @GrupaM in ('O','P')
			if @SalComenzi=1 and abs(@LMCassOcaz) between 0.01 and 0.02
				select @LMCassCom=@LMCassCom+@LMCassOcaz, @LMCassOcaz=0
		End	
		if @Reva=1 and @CasaSanatate<>'CNAS'
		Begin
			set @LMCassComDafora=@LMCassComDafora+@CassCom
			set @LMCassPDafora=@LMCassPDafora-@CassCom
		End	
		if @CalcITM=1 and (@GrupaM not in ('O','P') and @Pensionar<>5 
			or @NuITMColab=0 and @GrupaM in ('O','P') or @NuITMPens=0 and @Pensionar=5)
		Begin
			set @ITMCom=round(@ValoarePozITM2*@pITM/100,2)
			set @LMItmCom=@LMItmCom+@ITMCom
			set @LMItm=@LMItm-@ITMCom
		End	
		set @SomajCom=round(@ValoarePozSomaj2*(case when @Somaj_1<>0 and (@SalComenzi=0 or @SomajUnitate<>0) then @pSomaj/100 else 0 end),2)
		set @LMSomajCom=@LMSomajCom+@SomajCom
		select @LMSomajPerm=@LMSomajPerm-@SomajCom where not(@GrupaM in ('O','P'))
		if @SalComenzi=1 and abs(@LMSomajPerm) between 0.01 and 0.02
			select @LMSomajCom=@LMSomajCom+@LMSomajPerm, @LMSomajPerm=0
		select @LMSomajOcaz=@LMSomajOcaz-@SomajCom where @GrupaM in ('O','P')
		if @SalComenzi=1 and abs(@LMSomajOcaz) between 0.01 and 0.02
			select @LMSomajCom=@LMSomajCom+@LMSomajOcaz, @LMSomajOcaz=0
		
		if @GrupaM not in ('O','P') 
		Begin
			set @FondGarCom=round(@ValoarePoz2_CMStat*(case when @Marca='' or @FondGar<>0 then @pFondGar/100 else 0 end),2)
			set @LMFondGarCom=@LMFondGarCom+@FondGarCom
			set @LMFondGar=@LMFondGar-@FondGarCom
			if @SalComenzi=1 and abs(@LMFondGar) between 0.01 and 0.02
				select @LMFondGarCom=@LMFondGarCom+@LMFondGar, @LMFondGar=0
		End	
		if @NCSubvSomaj=1
		Begin
			set @SubvSomajCom=@SubvSomaj*(case when @ValRealizataMarca=0 then 1 else @Cantitate*@Tarif_unitar/@ValRealizataMarca end)
			set @LMSubvSomajCom=@LMSubvSomajCom+@SubvSomajCom
			set @LMSubvSomaj=@LMSubvSomaj-@SubvSomajCom
			set @ScutireSomajCom=@ScutireSomaj*(case when @ValRealizataMarca=0 then 1 else @Cantitate*@Tarif_unitar/@ValRealizataMarca end)
			set @LMScutireSomajCom=@LMScutireSomajCom+@ScutireSomajCom
			set @LMScutireSomaj=@LMScutireSomaj-@ScutireSomajCom
		End	
		fetch next from CasLMCom into @Data, @Marca, @Lm, @NumarDocRC, @Comanda, @Cantitate, @Tarif_unitar, @Norma_de_timp, 
			@GrupaMPontaj, @Valoare_manopera, @Ore_realizate_in_acord, @IndCMUnitate, @CMUnitate, @IndCMCAS, @CMCAS, @IndCMFaambp, 
			@SomajTehnic, @Venit_total, @Spor_vechime, @Spor_specific, @CasaSanatate, @ValRealizataMarca, 
			@VenitNelucratPoz, @VenitCorectiiPoz, @Pensionar, @GrupaM, @TipColab, @Somaj_1, 
			@SubvSomaj, @ScutireSomaj, @BazaCasCM, @BazaFaambpCM, @SomajUnitate, @FondGar, @UltNrDocMLM
	set @gfetch=@@fetch_status
	End

	set @AnActivDeb=(case when @NCAnActiv=1 then '.'+rtrim(@ActivitateBrut) else '' end)
	set @AnActivCre=(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(@ActivitateBrut) else '' end)
	if @Continuare=1
	Begin
		select @IndBug=''
		Set @ContDebitor=rtrim(@DebitCASPerm)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditCASPerm)+rtrim(@AnActivDeb)
		if @NCIndBug=1
			select @IndBug=Comanda from config_nc where Numar_pozitie=100
		set @Explicatii='C.A.S. - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCasCom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, @IndBug, @AnLMCASPerm, '', '', 0

		Set @ContDebitor=rtrim(@DebitCCI)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditCCI)+rtrim(@AnActivDeb)
		if @NCIndBug=1
			select @IndBug=Comanda from config_nc where Numar_pozitie=120
		set @Explicatii='CCI '+rtrim(convert(char(6),@pCCI))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCCICom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, @IndBug, @AnLMCCI, '', '', 0

		Set @ContDebitor=rtrim(@DebitCASSPerm)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditCASSPerm)+(case when @Reva=1 then '.1' else rtrim(@AnActivDeb) end)
		if @NCIndBug=1
			select @IndBug=Comanda from config_nc where Numar_pozitie=110
		set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCassCom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, @IndBug, @AnLMCassPerm, '', '', 0

		Set @ContDebitor=rtrim(@DebitCASSPerm)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditCASSPerm)+(case when @Reva=1 then '.2' else rtrim(@AnActivDeb) end)
		set @Explicatii='Asig.San. platit unitate '+rtrim(convert(char(6),@pCass))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCassComDafora, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', @AnLMCassPerm, '', '', 0

		Set @ContDebitor=rtrim(@DebitFaambpPerm)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditFaambpPerm)+rtrim(@AnActivDeb)
		if @NCIndBug=1
			select @IndBug=Comanda from config_nc where Numar_pozitie=115
		set @Explicatii='Fd.special acc. de munca '+rtrim(convert(char(6),@pFaambp))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMFaambpCom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, @IndBug, @AnLMFaambpPerm, '', '', 0

		Set @ContDebitor=rtrim(@DebitITM)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditITM)+rtrim(@AnActivDeb)
		set @Explicatii='Camera de munca '+rtrim(convert(char(6),@pITM))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMITMCom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', @AnLMITM, '', '', 0

		Set @ContDebitor=rtrim(@DebitSomajPerm)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditSomajPerm)+rtrim(@AnActivDeb)
		if @NCIndBug=1
			select @IndBug=Comanda from config_nc where Numar_pozitie=105
		set @Explicatii='Somaj '+rtrim(convert(char(6),@pSomaj))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMSomajCom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, @IndBug, @AnLMSomajPerm, '', '', 0

		Set @ContDebitor=rtrim(@DebitFondGar)+rtrim(@AnActivDeb)
		Set @ContCreditor=rtrim(@CreditFondGar)+rtrim(@AnActivDeb)
		if @NCIndBug=1
			select @IndBug=Comanda from config_nc where Numar_pozitie=125
		set @Explicatii='Fond de garantare '+rtrim(convert(char(6),@pFondGar))+'% - '+rtrim(@gLm)+' '+rtrim(@gComanda)
		exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMFondGarCom, @NumarDoc, 
		@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, @IndBug, @AnLMFondGar, '', '', 0
		if @NCSubvSomaj=1
		Begin
			set @Explicatii='Total Subventii Somaj - '+rtrim(@gLm)+rtrim(@gComanda)
			exec scriuNCsalarii @dataSus, @DebitSubvSomaj, @CreditSubvSomaj, @LMSubvSomajCom, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', 0, '', '', 0

			set @Explicatii='Total Scutiri Somaj - '+rtrim(@gLm)+rtrim(@gComanda)
			exec scriuNCsalarii @dataSus, @CreditSomajPerm, @CreditSubvSomaj, @LMScutireSomajCom, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @gLm, @gComanda, '', 0, '', '', 0
		End
	End
	set @gMarca=@Marca
	set @gLm=@Lm
	set @gComanda=@Comanda
End
close CasLMCom
Deallocate CasLMCom
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenNCCasLMCom (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec GenNCCasLMCom '02/01/2011', '02/28/2011', '', 1, 309014
*/
