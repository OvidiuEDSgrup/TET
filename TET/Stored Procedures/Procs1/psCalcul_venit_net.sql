--***
/**	proc. calcul venit net	*/
Create procedure psCalcul_venit_net
	@dataJos datetime, @dataSus datetime, @marcaJos char(6), @locmJos char(9), @Inversare int
As
Begin try 
	declare @utilizator varchar(20),@multiFirma int,@Salar_minim float,@Salar_mediu float,@IndRefSomaj float,@OreLuna int,@Sindicat_procentual int,
	@AnRegCom int, @DataExpOUG6 datetime, @STOUG28 int, @Adun_OIT_RN int, @cod_sindicat char(13), @procent_sindicat float, @LM_statpl int,
	@Subtipret int, @Subtipcor int, @Sal_comp int, @Cor_salcomp char(20), @Acorda_part_profit int, @Cor_part_profit char(20), 
	@Aloc_hrana int, @Cor_aloc_hrana char(20), @IT1SuspContr int, @IT2SuspContr int, @IT3SuspContr int, @ImpozitTichete int, @DataImpTicJ datetime, @DataImpTicS datetime, 
	@Data1_an datetime, @dataSus_ant datetime,
	@pCASind float, @pCASSind float, @pSomajind float,@pSomajI float,@pCASgr3 float,@pCASgr2 float,@pCASgr1 float,
	@pCCI float,@CoefCAS float, @CoefCCI float, @pCASSU float,@pSomajU float,@pFondGar float,@pFambp float,@CalculITM int,@pITM float,
	@Buget int,@InstPubl int,@CASSColab int,@NuITMcolab int,@NuITMpens int,@Somajcolab int,@CCIcolabP int,@CCIcolabO int,
	@Chindpont int,@ChindLunacrt int, @Chindvnet int,@NuRotBI int,@CompSalarnet int,@SalarNetValuta int,@SalarNetFCM int,
	@NuCAS_H int,@NuCASS_H int,@Imps_H int,@CASSimps_K int,@Somaj_K int,@CCI_K int,@NuASS_J int,@CAS_J int,@NuASS_N int,@NuASSA_N int,@CorU_RP int,@CAS_U int,
	@VenitBrutCuded float,@VenitBrutFaraDed float,@ImpozitNegativ int, @Tichete int, @NuDPSH int, @AdVenNet_Q int,@LucrCuDiurneNeimpoz int,
	@Dafora int,@Colas int,@Pasmatex int,@Drumor int,@Plastidr int, @lmCorectie varchar(9)

 	set @utilizator = dbo.fIaUtilizator(null)
	select @multiFirma=0, @lmCorectie=''
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	if @multiFirma=1
		set @lmCorectie=@locmJos

	set @Data1_an=dbo.boy(@dataJos)
	set @dataSus_ant=@dataJos-1

--	citire parametrii
	select @Sindicat_procentual=max(case when Parametru='SIND%' then Val_logica else 0 end),
		@procent_sindicat=max(case when Parametru='SIND%' then Val_numerica else 0 end),
		@cod_sindicat=max(case when Parametru='SIND%' then Val_alfanumerica else '' end),
		@AnRegCom=max(case when Parametru='REGCOMAN' then Val_numerica else 0 end),
		@Adun_OIT_RN=max(case when Parametru='OINTNRN' then Val_logica else 0 end),
		@LM_statpl=max(case when Parametru='LOCMSALAR' then Val_logica else 0 end),
		@NuCAS_H=max(case when Parametru='NUCAS-H' then Val_logica else 0 end),
		@NuCASS_H=max(case when Parametru='NUASS-H' then Val_logica else 0 end),
		@Imps_H=max(case when Parametru='IMPSEP-H' then Val_logica else 0 end),
		@NuASS_J=max(case when Parametru='NUASS-J' then Val_logica else 0 end),
		@CAS_J=max(case when Parametru='CAS-J' then Val_logica else 0 end),
		@Cassimps_K=max(case when Parametru='ASSIMPS-K' then Val_logica else 0 end),
		@Somaj_K=max(case when Parametru='SOMAJ-K' then Val_logica else 0 end),
		@CCI_K=max(case when Parametru='CCI-K' then Val_logica else 0 end),
		@NuASS_N=max(case when Parametru='NUASS-N' then Val_logica else 0 end),
		@NuASSA_N=max(case when Parametru='NUASSA-N' then Val_logica else 0 end),
		@CorU_RP=max(case when Parametru='ADRPL-U' then Val_logica else 0 end),
		@CAS_U=max(case when Parametru='CALCAS-U' then Val_logica else 0 end),
		@Subtipret=max(case when Parametru='SUBTIPRET' then Val_logica else 0 end),
		@Subtipcor=max(case when Parametru='SUBTIPCOR' then Val_logica else 0 end),
		@Sal_comp=max(case when Parametru='SALCOMP' then Val_logica else 0 end),
		@Cor_salcomp=max(case when Parametru='SALCOMP' then Val_alfanumerica else '' end),
		@Acorda_part_profit=max(case when Parametru='PSALPROF' then Val_logica else 0 end),
		@Cor_part_profit=max(case when Parametru='PSALPROF' then Val_alfanumerica else '' end),
		@Aloc_hrana=max(case when Parametru='ALOCHRANA' then Val_logica else 0 end),
		@Cor_aloc_hrana=max(case when Parametru='ALOCHRANA' then Val_alfanumerica else '' end),
		@IT1SuspContr=max(case when Parametru='IT1-SUSPC' then Val_logica else 0 end),
		@IT2SuspContr=max(case when Parametru='PROC2INT' then Val_logica else 0 end),
		@IT3SuspContr=max(case when Parametru='PROC3INT' then Val_logica else 0 end),
		@CoefCAS=max(case when Parametru='COEFCAS' then Val_numerica else 0 end),
		@CoefCCI=max(case when Parametru='COEFCCI' then Val_numerica else 0 end),
		@CalculITM=max(case when Parametru='1%-CAMERA' then Val_logica else 0 end),
		@Buget=max(case when Parametru='UNITBUGET' then Val_logica else 0 end),
		@InstPubl=max(case when Parametru='INSTPUBL' then Val_logica else 0 end),
		@CASSColab=max(case when Parametru='CALFASC' then Val_logica else 0 end),
		@NuITMcolab=max(case when Parametru='NCALPCMC' then Val_logica else 0 end),
		@NuITMpens=max(case when Parametru='NCALPCMPE' then Val_logica else 0 end),
		@Somajcolab=max(case when Parametru='CAL5FR1' then Val_logica else 0 end),
		@CCIcolabP=max(case when Parametru='CCICOLAB' then Val_logica else 0 end),
		@CCIcolabO=max(case when Parametru='CCICOLABO' then Val_logica else 0 end),
		@ChindPont=max(case when Parametru='CHINDPON' then Val_logica else 0 end),
		@ChindLunacrt=max(case when Parametru='CHINDLCRT' then Val_logica else 0 end),
		@ChindVnet=max(case when Parametru='CHINDVEN' then Val_logica else 0 end),
		@NuRoTBI=max(case when Parametru='BAZANEROT' then Val_logica else 0 end),
		@CompSalarnet=max(case when Parametru='COMPSALN' then Val_logica else 0 end),
		@SalarNetValuta=max(case when Parametru='SALNETV' then Val_logica else 0 end),
		@SalarNetFCM=max(case when Parametru='SALNPO-CM' then Val_logica else 0 end),
		@VenitBrutCuded=max(case when Parametru='VBCUDEDP' then Val_numerica else 0 end),
		@VenitBrutFaraDed=max(case when Parametru='VBFDEDP' then Val_numerica else 0 end),
		@ImpozitNegativ=max(case when Parametru='CIMPZNEG' then Val_logica else 0 end),
		@Tichete=max(case when Parametru='TICHETE' then Val_logica else 0 end),
		@NuDPSH=max(case when Parametru='NUDPSH' then Val_logica else 0 end),
		@AdVenNet_Q=max(case when Parametru='ADVNET-Q' then Val_logica else 0 end),
		@LucrCuDiurneNeimpoz=max(case when Parametru='DIUNEIMP' then Val_logica else 0 end),
		@Dafora=max(case when Parametru='DAFORA' then Val_logica else 0 end),
		@Colas=max(case when Parametru='COLAS' then Val_logica else 0 end),
		@Pasmatex=max(case when Parametru='PASMATEX' then Val_logica else 0 end),
		@Drumor=max(case when Parametru='DRUMOR' then Val_logica else 0 end),
		@Plastidr=max(case when Parametru='PLASTIDR' then Val_logica else 0 end)
	from par 
	where Tip_parametru='PS' and Parametru in ('SIND%','REGCOMAN','COLAS','OINTNRN','LOCMSALAR',
			'NUCAS-H','NUASS-H','IMPSEP-H','NUASS-J','CAS-J','ASSIMPS-K','SOMAJ-K','CCI-K','NUASS-N','NUASSA-N','ADRPL-U','CALCAS-U',
			'SUBTIPRET','SUBTIPCOR','SALCOMP','PSALPROF','ALOCHRANA','IT1-SUSPC','PROC2INT','PROC3INT','COEFCAS','COEFCCI','1%-CAMERA',
			'UNITBUGET','INSTPUBL','CALFASC','NCALPCMC','NCALPCMPE','CAL5FR1','CCICOLAB','CCICOLABO',
			'CHINDPON','CHINDLCRT','CHINDVEN','BAZANEROT','COMPSALN','SALNETV','SALNPO-CM','VBCUDEDP','VBFDEDP','CIMPZNEG','TICHETE','NUDPSH','ADVNET-Q','DIUNEIMP')
		or Tip_parametru='SP' and Parametru in ('COLAS','DAFORA','PASMATEX','DRUMOR','PLASTIDR')

	set @DataExpOUG6=dbo.EOY(convert(datetime,'01/01/'+str(@AnRegCom+3,4)))
	set @CoefCAS=@CoefCAS/1000000
	set @CoefCCI=@CoefCCI/1000000

--	citire parametrii lunari
	select @Salar_minim=max(case when Parametru='S-MIN-BR' then Val_numerica else 0 end),
		@Salar_mediu=max(case when Parametru='SALMBRUT' then Val_numerica else 0 end),
		@IndRefSomaj=max(case when Parametru='SOMAJ-ISR' then Val_numerica else 0 end),
		@OreLuna=max(case when Parametru='ORE_LUNA' then Val_numerica else 0 end),
		@pCASind=max(case when Parametru='CASINDIV' then Val_numerica else 0 end),
		@pCASSind=max(case when Parametru='CASSIND' then Val_numerica else 0 end),
		@pSomajind=max(case when Parametru='SOMAJIND' then Val_numerica else 0 end),
		@pCASgr3=max(case when Parametru='CASGRUPA3' then Val_numerica else 0 end),
		@pCASgr2=max(case when Parametru='CASGRUPA2' then Val_numerica else 0 end),
		@pCASgr1=max(case when Parametru='CASGRUPA1' then Val_numerica else 0 end),
		@pCCI=max(case when Parametru='COTACCI' then Val_numerica else 0 end),
		@pCASSU=max(case when Parametru='CASSUNIT' then Val_numerica else 0 end),
		@pSomajU=max(case when Parametru='3.5%SOMAJ' then Val_numerica else 0 end),
		@pFondGar=max(case when Parametru='FONDGAR' then Val_numerica else 0 end),
		@pFambp=max(case when Parametru='0.5%ACCM' then Val_numerica else 0 end),
		@pITM=max(case when Parametru='1%-CAMERA' then Val_numerica else 0 end),
		@STOUG28=max(case when Parametru='STOUG28' then Val_logica else 0 end),
		@ImpozitTichete=max(case when Parametru='DJIMPZTIC' then Val_logica else 0 end),
		@DataImpTicJ=max(case when Parametru='DJIMPZTIC' then Val_data else '' end),
		@DataImpTicS=max(case when Parametru='DSIMPZTIC' then Val_data else '' end)
	from par_lunari
	where Data=@dataSus and tip='PS' 
		and Parametru in ('S-MIN-BR','SALMBRUT','SOMAJ-ISR','ORE_LUNA','CASINDIV','CASSIND','SOMAJIND',
		'CASGRUPA3','CASGRUPA2','CASGRUPA1','COTACCI','CASSUNIT','3.5%SOMAJ','FONDGAR','0.5%ACCM','1%-CAMERA','STOUG28','DJIMPZTIC','DSIMPZTIC')

	set @pCASgr3=@pCASgr3-@pCASind
	set @pCASgr2=@pCASgr2-@pCASind
	set @pCASgr1=@pCASgr1-@pCASind
	set @DataImpTicJ=(case when @DataImpTicJ='01/01/1901' then @dataJos else @DataImpTicJ end)
	set @DataImpTicS=(case when @DataImpTicS='01/01/1901' then @dataSus else @DataImpTicS end)
	
	declare @Data datetime,@Marca char(6),@SalarDeBaza float,@OreLucr int,@OreNoapte int,@OreRN int,@OreIT int, @OreOblig int,@OreCFS int,@OreCO int,@OreCM int,@Invoiri int,
	@Nemotivate int,@OreJust int,@IndFAMBP float,@CMunit float,@CMcas float,@Diurna float,@SumaImpoz float,@ConsAdmin float,@SumaImpsep float,@AjDeces float, @Venit_total float,
	@RL float,@Locm char(9),@CorQ float,@CorT float,@CorU float,@RetSindicat float,@RLpont float,@RLbrut float, @GrpMpont char(1),@Somaj1P int,@AsSanP float,@TipImpozP char(1),
	@ProcImpoz int,@CheltDed decimal(10),@GrpMP char(1),@TipcolabP char(3),@AlteSurseP char(1), @GradInvP char(1),@TipdedSomajP float,@DataAng datetime,@Plecat char(1),
	@ModAngP char(1),@DataPlecP datetime,@Sind char(1),@DataIcvsom datetime,@DataEcvsom datetime,@NrPersintr int,@BazaCN float,@BazaCD float,@BazaCS float, 
	@Indcmunit19 float, @Indcmcas19 float,@Orelunacm int,@Indcm float,@Indcmcas18 float,@Zcm18 int,@Zcm18ant int,@BazaCASIant float,
	@BazaCASCMant float,@Zcm2341011 int,@Indcm234 float,@Indcmunit234 float,@Zcm15 int,@Zcm8915 int,@Indcm8915 float,
	@Zcm78 int,@Indcm78 float,@Indcmsomaj float,@Ingrcopsarcina int,@Zcm_unitate int,@Zcm_fonduri int,@PersNecontractual char(1),
	@OUG13 int,@OUG6 int,@FaraAltVenitPtCASS int,@uMarca2CNP int,@uMarca2CNPCM int,@CNP char(13),@Pensmax_ded float,@Pensded_lun float,@Pensded_ant float,@Pensluna float,@SalComp float,@AlocHrana float,
	@SomajTehn float,@OreST int,@SumaNeimp float, @ValTichete float,@uMarca2CNPSomaj int, @tipAsigurat int, @AvantajeMat float, @AvantajeMatImpozabile float, @DiurneNeimpoz float, 
	@PensieFUnitate float, @Part_profit float, @SomajTehnicSusp float, @OrdinePlafonareCAS float, @OreCMSubvSomaj int, @ExpatriatCuA1 int

	declare @TBCASCN decimal(12,2),@TBCASCD decimal(12,2),@TBCASCS decimal(12,2),@TCAS decimal(12,2),
	@TBCASCMCN decimal(12,2),@TBCASCMCD decimal(12,2),@TBCASCMCS decimal(12,2),@TCASCM decimal(12,2),
	@TBCASS decimal(12,2),@TCASS decimal(12,2),@TBCASSFambpS decimal(12,2),@TCASSFambpS decimal(12,2),
	@TBCASSFambpA decimal(12,2),@TCASSFambpA decimal(12,2),@TBsomajPCON decimal(12,2),@TBsomajPNECON decimal(12,2),@TSomaj decimal(12,2),
	@TBCCI decimal(12,2),@TCCI decimal(12,2),@TBCCIFambp decimal(12,2),@TCCIFambp decimal(12,2),
	@TBFambp decimal(12,2),@TFambp decimal(12,2),@TBFG decimal(12,2),@TFG decimal(12,2),@TBITM decimal(12,2),@TITM decimal(12,2)

	select @TBCASCN=0,@TBCASCD=0,@TBCASCS=0,@TCAS=0,@TBCASCMCN=0,@TBCASCMCD=0,@TBCASCMCS=0,
	@TCASCM=0,@TBCASS=0,@TCASS=0,@TBCASSFambpS=0,@TCASSFambpS=0,@TBCASSFambpA=0,@TCASSFambpA=0,
	@TBsomajPCON=0,@TBsomajPNECON=0,@TSomaj=0,@TBCCI=0,@TCCI=0,@TBCCIFambp=0,@TCCIFambp=0,@TBFambp=0, @TFambp=0,@TBITM=0,@TITM=0, @TBFG=0,@TFG=0

	if object_id('tempdb..#ordinePlafonareCAS') is not null drop table #ordinePlafonareCAS
	if object_id('tempdb..#tipAsigurat') is not null drop table #tipAsigurat
	if object_id('tempdb..#pontaj_marca_locm') is not null drop table #pontaj_marca_locm
	if object_id('tempdb..#Sume_cm_marca') is not null drop table #Sume_cm_marca
	if object_id('tempdb..#brut') is not null drop table #brut
	if object_id('tempdb..#personal') is not null drop table #personal
	
	Create table #Pontaj_marca_locm 
		(Data datetime, Marca char(6), Loc_de_munca char(9), Regim_de_lucru float, Grupa_de_munca char(1), Tip_salarizare char(1), 
		Coeficient_acord float, Ore_intr_tehn_1 int, Ore_intr_tehn_2 int, Ore_intemperii int, Ore_intr_tehn_3 float) 
	Create Unique Clustered Index [Marca_locm] ON #pontaj_marca_locm (Data Asc, Marca Asc, Loc_de_munca Asc)
	exec pPontaj_marca_locm @dataJos,@dataSus,@marcaJos,@locmJos

	Create table #Sume_cm_marca
		(Data datetime, Marca char(6), indcm_unit_19 float, indcm_cas_19 float, 
		ore_luna_cm float, indcm float, indcm_cas_18 float, zcm_18 int, zcm_18_ant int, baza_casi_ant float, baza_cascm_ant float, 
		zcm_2341011 int, indcm_234 float, indcm_unit_234 float, zcm15 int, zcm_8915 int, indcm_8915 float, zcm_78 int, indcm_78 float, 
		indcm_somaj float, ingrijire_copil_sarcina int, zcm_unitate int, zcm_fonduri int, zcm_subv_somaj int)
	Create Unique Clustered Index [Data_marca] ON #Sume_cm_marca (Data Asc, Marca Asc)
	exec pSume_cm_marca @dataJos,@dataSus,@marcaJos

	create table #tipAsigurat 
		(Data datetime, Marca char(6), TagAsigurat char(20), Tip_asigurat int, Pensionar int, Tip_contract char(2), Tip_functie char(1), Regim_de_lucru float)
	insert into #tipAsigurat
	exec Declaratia112TagAsigurat @dataJos, @dataSus, @locmJos

--	pun in tabela temporara ordinea privind plafonarea CAS-ului individual, valabila la data calculului de lichidare
	select Marca, ordineCAS into #ordinePlafonareCAS from 
	(select Marca, convert(int,Val_inf) as ordineCAS, RANK() over (partition by Marca order by Data_inf Desc) as ordine
	from extinfop f 
	where Cod_inf='ORDINECAS' and Val_inf<>'' and Data_inf<=@DataSus) a
	where Ordine=1

--	pun datele din personal in tabela temporara ca sa nu fac apel la prefiltare din LMFiltrare in fiecare select din cursorul de mai jos (necesar pentru multifirma)
	select p.* into #personal
	from personal p 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where (@marcaJos='' or p.marca=@marcaJos) 
		and (@locmJos='' or p.loc_de_munca like rtrim(@locmJos)+'%')
		and (@multiFirma=0 or dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null) 

--	pun datele din brut in tabela temporara ca sa nu fac apel la prefiltare din LMFiltrare in fiecare select din cursorul de mai jos (necesar pentru multifirma)
	select b.* into #brut 
	from brut b
		left outer join personal p on p.marca=b.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where data between @dataJos and @dataSus and (@marcaJos='' or b.marca=@marcaJos) 
		and (@locmJos='' or p.loc_de_munca like rtrim(@locmJos)+'%')
		and (@multiFirma=0 or dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null) 

	declare calcnet cursor for
--	cursor
	Select b.data,b.marca, max((case when @Buget=1 then p.salar_de_baza else p.salar_de_incadrare end)), 
	sum(b.ore_concediu_fara_salar),sum(b.ore_concediu_de_odihna),sum(b.ore_concediu_medical),sum(b.ore_invoiri),sum(b.ore_nemotivate),
	sum(b.ore_lucrate_regim_normal+(case when @Adun_OIT_RN=1 then 0 else b.Ore_intrerupere_tehnologica-isnull(t.Ore_Intr_tehn_2,0) end)
		+b.ore_obligatii_cetatenesti+b.ore_concediu_de_odihna+b.ore_concediu_medical+b.ore_invoiri+b.ore_nemotivate+b.ore_concediu_fara_salar
		+isnull(t.Ore_intemperii,0)+(case when @Colas=1 and @Adun_OIT_RN=1 or 1=1 then isnull(t.Ore_Intr_tehn_2,0) else 0 end)+isnull(t.Ore_Intr_tehn_3,0)),
	sum(b.spor_cond_9),sum(b.cmunitate),sum(b.cmcas),sum(b.diurna),sum(b.suma_impozabila),sum(b.cons_admin),sum(b.suma_imp_separat),sum(b.compensatie),sum(b.venit_total),
	max(b.spor_cond_10),
	(case when @LM_statpl=1 then max(p.loc_de_munca) else isnull((select max(c.loc_de_munca) from #brut c 
		where c.data=b.data and c.marca=b.marca and convert(char(1),c.Loc_munca_pt_stat_de_plata)='1'),max(p.loc_de_munca)) end), 
	isnull(max(c1.suma_corectie),0),0,isnull(sum(c3.suma_corectie),0),isnull(max(r.retinut_la_lichidare),0),
	isnull(max(t.regim_de_lucru),max(b.spor_cond_10)),isnull(max(t.grupa_de_munca),max(p.grupa_de_munca)),
	max(p.somaj_1),max(p.as_sanatate),max(p.tip_impozitare),isnull(max(e3.Procent),0),round(sum(b.Venit_total)*isnull(max(e4.Procent/100),0),0),
	max(p.grupa_de_munca),
	(case when max(p.Grupa_de_munca) in ('N','D','S','C') and max(p.tip_colab)='' 
		and exists (select 1 from vechimi v where v.Marca=b.Marca and v.Tip='T' and v.Data_sfarsit between @datajos and max(p.Data_angajarii_in_unitate)) then 'FDP' else max(p.tip_colab) end), 
	max(convert(char(1),p.alte_surse)),max(p.grad_invalid),max(p.coef_invalid),max(p.data_angajarii_in_unitate), max(convert(char(1),loc_ramas_vacant)),
	max(p.mod_angajare),max(p.data_plec),max(convert(char(1),p.sindicalist)),
	max((case when isnull(e2.data_inf,'01/01/1901')='01/01/1901' then p.data_angajarii_in_unitate else isnull(e2.data_inf,'01/01/1901') end)),
	max(isnull(e.data_inf,'01/01/1901')),isnull((select count(1) from persintr s where s.data=b.data and s.marca=b.marca and s.coef_ded<>0),0),
	max(p.cod_numeric_personal) as CNP, max(convert(char(1),i.actionar)) as PersNecontractual, 
	(case when (day(max(p.Data_angajarii_in_unitate))=1 and b.data>=dbo.eom(max(p.Data_angajarii_in_unitate)) and b.data<=dbo.eom(DateAdd(month,5,max(p.Data_angajarii_in_unitate))) 
		or day(max(p.Data_angajarii_in_unitate))<>1 and b.data>=dbo.eom(DateAdd(month,1,max(p.Data_angajarii_in_unitate)))
		and b.data<=dbo.eom(DateAdd(month,6,max(p.Data_angajarii_in_unitate)))) and upper(max(rtrim(isnull(e5.Val_inf,''))))='DA' then 1 else 0 end) as OUG13,
	(case when b.data<=@DataExpOUG6 and upper(max(rtrim(isnull(e6.Val_inf,''))))='DA' then 1 else 0 end) as OUG6, 
	(case when max(p.Grupa_de_munca)='O' and max(p.Tip_colab) in ('DAC','CCC','ECT') and upper(max(rtrim(isnull(e7.Val_inf,''))))='DA' then 1 else 0 end) as FaraAltVenitPtCASS, 
	(case when max(p.Grupa_de_munca) in ('O','P') and upper(max(rtrim(isnull(e8.Val_inf,''))))='DA' then 1 else 0 end) as ExpatriatCuA1,
--	cursor 1
	sum(b.venit_cond_normale-(case when t.grupa_de_munca='N' then b.ind_c_medical_unitate+b.cmunitate when p.grupa_de_munca='N' or p.grupa_de_munca='P' then b.ind_c_medical_unitate+b.cmunitate else 0 end)
		-(case when t.grupa_de_munca='N' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 when p.grupa_de_munca='N' or p.grupa_de_munca='P' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 else 0 end)
		-(case when @Cassimps_K=1 then (case when t.grupa_de_munca='N' and p.grupa_de_munca<>'P' then b.cons_admin when p.grupa_de_munca='N' then b.cons_admin else 0 end) else 0 end)
		-(case when @STOUG28=1 then (case when t.grupa_de_munca='N' then round(b.Ind_invoiri,0) when p.grupa_de_munca='N' then round(b.Ind_invoiri,0) else 0 end) else 0 end)
		-(case when t.grupa_de_munca='N' then isnull(pf.Suma_corectie,0) else 0 end)
		/*+(case when t.grupa_de_munca='N' then isnull(ai.Suma_corectie,0) else 0 end)*/),
	sum(b.venit_cond_deosebite-(case when t.grupa_de_munca='D' then b.ind_c_medical_unitate+b.cmunitate when p.grupa_de_munca='D' then b.ind_c_medical_unitate+b.cmunitate else 0 end)
		-(case when t.grupa_de_munca='D' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 when p.grupa_de_munca='D' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 else 0 end)
		-(case when @Cassimps_K=1 then (case when t.grupa_de_munca='D' then b.cons_admin when p.grupa_de_munca='D' then b.cons_admin else 0 end) else 0 end)
		-(case when @STOUG28=1 then (case when t.grupa_de_munca='D' then round(b.Ind_invoiri,0) when p.grupa_de_munca='D' then round(b.Ind_invoiri,0) else 0 end) else 0 end)
		-(case when t.grupa_de_munca='D' then isnull(pf.Suma_corectie,0) else 0 end)
		/*+(case when t.grupa_de_munca='D' then isnull(ai.Suma_corectie,0) else 0 end)*/),
	sum(b.venit_cond_speciale-(case when t.grupa_de_munca='S' then b.ind_c_medical_unitate+b.cmunitate when p.grupa_de_munca='S' then b.ind_c_medical_unitate+b.cmunitate else 0 end)
		-(case when t.grupa_de_munca='S' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 when p.grupa_de_munca='S' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 else 0 end)
		-(case when @Cassimps_K=1 then (case when t.grupa_de_munca='S' then b.cons_admin when p.grupa_de_munca='S' then b.cons_admin else 0 end) else 0 end)
		-(case when @STOUG28=1 then (case when t.grupa_de_munca='S' then round(b.Ind_invoiri,0) when p.grupa_de_munca='S' then round(b.Ind_invoiri,0) else 0 end) else 0 end)
		-(case when t.grupa_de_munca='S' then isnull(pf.Suma_corectie,0) else 0 end)
		/*+(case when t.grupa_de_munca='S' then isnull(ai.Suma_corectie,0) else 0 end)*/),
	isnull(max(m.indcm_unit_19),0), isnull(max(m.indcm_cas_19),0),isnull(max(m.ore_luna_cm),@OreLuna),isnull(max(m.indcm),0), isnull(max(m.indcm_cas_18),0), isnull(max(m.zcm_18),0), 
	isnull(max(zcm_18_ant),0), isnull(max(baza_casi_ant),0), isnull(max(baza_cascm_ant),0), isnull(max(zcm_2341011),0),isnull(max(indcm_234),0), isnull(max(indcm_unit_234),0), 
	isnull(max(zcm15),0), isnull(max(zcm_8915),0), isnull(max(indcm_8915),0), isnull(max(zcm_78),0), isnull(max(indcm_78),0),isnull(max(indcm_somaj),0), 
	(case when isnull(max(m.ingrijire_copil_sarcina),0)<>0 then 1 else 0 end), isnull(max(zcm_unitate),0), isnull(max(zcm_fonduri),0), 
	isnull((select count(1) from #brut b1 
			left outer join #ordinePlafonareCAS op1 on op1.Marca=b1.Marca 
		where max(p.Tip_colab) not in ('DAC','CCC','ECT') and b1.data=@dataSus 
			and (isnull(op1.ordineCAS,0)<max(isnull(op.ordineCAS,0)) or isnull(op1.ordineCAS,0)=max(isnull(op.OrdineCAS,0)) and b1.marca<b.marca) 
			--and b1.marca<b.marca 
			and exists (select p1.marca from #personal p1 where p1.Marca=b1.marca and p1.cod_numeric_personal=max(p.cod_numeric_personal) and (p1.loc_ramas_vacant=0 or p1.Data_plec>@dataJos) 
				and p1.Grupa_de_munca in ('N','D','S','C','P') and p1.Tip_colab not in ('DAC','CCC','ECT')) 
	/*and (select count(1) from #brut b2 where b2.data=@dataSus and b2.marca>b.marca 
		and exists (select p2.marca from #personal p2 where p2.Marca=b2.marca and p2.cod_numeric_personal=max(p.cod_numeric_personal) and (p2.loc_ramas_vacant=0 or p2.Data_plec>@dataJos)))=0*/),0),
	isnull((select count(1) from #brut b1 where b1.data=@dataSus and b1.marca<b.marca /* am inlocuit in conditia de mai inainte <> cu < */
		and exists (select p1.marca from #personal p1 where p1.Marca=b1.marca and p1.cod_numeric_personal=max(p.cod_numeric_personal) and p1.Grupa_de_munca in ('N','D','S','C','P'))),0) as uMarca2CNPCM,
	max(convert(float,isnull(e1.val_inf,''))) as Pensie_max_ded,max(isnull(e1.procent,0)),
	isnull((select sum(n.ded_baza) from net n where n.data between @Data1_an and @dataSus_ant and n.marca=b.marca and day(n.data)=1),0),
	isnull((select sum(r1.Retinere_progr_la_avans+r1.Retinere_progr_la_lichidare) from resal r1 where r1.data between @dataJos and @dataSus and r1.marca=b.marca 
		and r1.cod_beneficiar in (select cod_beneficiar from benret where @Subtipret=0 and tip_retinere='5' or @Subtipret=1 
			and tip_retinere in (select subtip from tipret where tip_retinere='5'))),0),
	sum(isnull(c4.Suma_corectie,0)) as SalComp,
	isnull((select sum(suma_corectie) from corectii c5 where @Aloc_hrana=1 and c5.data between @dataJos and @dataSus and c5.marca=b.marca 
		and (@Subtipcor=0 and charindex(c5.tip_corectie_venit,@Cor_aloc_hrana)<>0 
			or @Subtipcor=1 and c5.Tip_corectie_venit in (select s.Subtip from Subtipcor s where charindex(s.tip_corectie_venit,@Cor_aloc_hrana)<>0))),0),
	sum((case when @STOUG28=1 then round(b.Ind_invoiri,0) else 0 end)),sum(isnull(t.Ore_intr_tehn_1,0)+isnull(t.Ore_intr_tehn_2,0)+isnull(t.Ore_intr_tehn_3,0)),
	max(isnull(n.Suma_neimpozabila,0)), max(isnull(ft.Valoare_tichete,0)), 
	(case when year(@dataSus)<=2010 
		then isnull((select count(1) from #brut b1 where max(p.Tip_colab) not in ('DAC','CCC','ECT') and max(p.Grupa_de_munca)<>'C' and max(p.Somaj_1)<>0 and b1.data=@dataSus 
			and b1.marca<b.marca and exists (select p1.marca from #personal p1 where p1.Marca=b1.marca and p1.cod_numeric_personal=max(p.cod_numeric_personal) 
			and (p1.loc_ramas_vacant=0 or p1.Data_plec>@dataJos) and p1.Somaj_1<>0 and p1.Grupa_de_munca in ('N','D','S','O','P') and p1.Tip_colab not in ('DAC','CCC','ECT')) 
			and (select count(1) from #brut b2 where b2.data=@dataSus and b2.marca>b.marca 
			and exists (select p2.marca from #personal p2 where p2.Marca=b2.marca and p2.cod_numeric_personal=max(p.cod_numeric_personal) and p2.Somaj_1<>0 and p2.Grupa_de_munca<>'C' 
			and (p2.loc_ramas_vacant=0 or p2.Data_plec>@dataJos)))=0),0)
	else isnull((select count(1) from #brut b1 
			left outer join #ordinePlafonareCAS op1 on op1.Marca=b1.Marca 
		where max(p.Somaj_1)<>0 and b1.data=@dataSus 
			and (isnull(op1.ordineCAS,0)<max(isnull(op.ordineCAS,0)) or isnull(op1.ordineCAS,0)=max(isnull(op.OrdineCAS,0)) and b1.marca<b.marca)
			and exists (select p1.marca from #personal p1 left outer join #tipAsigurat a2 on b1.data=a2.data and b1.marca=a2.marca 
		where p1.Marca=b1.marca and p1.cod_numeric_personal=max(p.cod_numeric_personal) and a2.Tip_asigurat=max(a1.Tip_asigurat) and a2.Tip_contract=max(a1.Tip_contract) 
		and (p1.loc_ramas_vacant=0 or p1.Data_plec>@dataJos) and p1.Somaj_1<>0 and p1.Tip_colab not in ('DAC','CCC','ECT'))
		and (select count(1) from #brut b2 
				left outer join #ordinePlafonareCAS op2 on op2.Marca=b1.Marca 
			where b2.data=@dataSus 
				and (isnull(op2.ordineCAS,0)>max(isnull(op.ordineCAS,0)) or isnull(op2.ordineCAS,0)=max(isnull(op.OrdineCAS,0)) and b2.marca>b.marca)
				and exists (select p2.marca from #personal p2 left outer join #tipAsigurat a3 on b2.data=a3.data and b2.marca=a3.marca 
			where p2.Marca=b2.marca and p2.cod_numeric_personal=max(p.cod_numeric_personal) and a3.Tip_asigurat=max(a1.Tip_asigurat) and a3.Tip_contract=max(a1.Tip_contract) and p2.Somaj_1<>0 
			and (p2.loc_ramas_vacant=0 or p2.Data_plec>@dataJos)))=0),0) end) as uMarca2CNPSomaj, 
	max(a1.tip_asigurat) as tip_asigurat, 
	sum(isnull(q.Suma_corectie,0)), sum(isnull(ai.Suma_corectie,0)), sum(isnull(w.Suma_corectie,0)),max(isnull(pf.Suma_corectie,0)) as PensieFUnitate, sum(isnull(pp.Suma_corectie,0)), 
	sum((case when @IT1SuspContr=1 then b.Ind_intrerupere_tehnologica else 0 end)+(case when @IT2SuspContr=1 then b.Ind_invoiri else 0 end)
	+(case when @IT3SuspContr=1 then b.Spor_cond_8 else 0 end)) as SomajTehnicSusp,
	max(isnull(op.ordineCAS,0)) as OrdinePlafonareCAS, isnull(max(m.zcm_subv_somaj),0)*max(b.spor_cond_10) as OreCMSubvSomaj
	from #brut b
		left outer join personal p on p.marca=b.marca
		left outer join infopers i on i.marca=b.marca
		left outer join net n on n.Data=b.Data and n.marca=b.marca
		left outer join resal r on r.data=@dataSus and r.marca=b.marca and r.cod_beneficiar in (dbo.fCodb_sindicat(b.marca,@dataSus),@cod_sindicat)
			and (not(p.sindicalist=1 and @procent_sindicat<>0) or left(r.numar_document,8)='SINDICAT')
		left outer join curscor c1 on c1.data=@dataSus and c1.marca=b.marca and c1.tip_corectie_venit='Q-'
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'U-', @marcaJos, @locmJos, 1) c3 on c3.Data=b.Data and c3.Marca=b.Marca and c3.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'T-', @marcaJos, @locmJos, 1) pf on pf.Data=b.Data and pf.Marca=b.Marca and pf.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, @Cor_salcomp, @marcaJos, @locmJos, 1) c4 on @Sal_comp=1 and c4.Data=b.Data and c4.Marca=b.Marca 
			and c4.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', @marcaJos, @locmJos, 1) q on q.Data=b.Data and q.Marca=b.Marca and q.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'AI', @marcaJos, @locmJos, 1) ai on ai.Data=b.Data and ai.Marca=b.Marca and ai.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, @Cor_part_profit, @marcaJos, @locmJos, 1) pp on @Acorda_part_profit=1 and pp.Data=b.Data and pp.Marca=b.Marca 
			and pp.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'W-', @marcaJos, @locmJos, 1) w on @LucrCuDiurneNeimpoz=1 and w.Data=b.Data and w.Marca=b.Marca and w.Loc_de_munca=b.Loc_de_munca
		left outer join extinfop e on e.marca=b.marca and e.cod_inf='DEXPSOMAJ'
		left outer join extinfop e1 on e1.marca=b.marca and e1.cod_inf='PENSIIF' and e1.data_inf=@Data1_an
		left outer join extinfop e2 on e2.marca=b.marca and e2.cod_inf='DCONVSOMAJ'
		left outer join extinfop e3 on e3.marca=b.marca and e3.cod_inf='PROCIMPOZ' and p.Grupa_de_munca in ('P','O')
		left outer join extinfop e4 on e4.marca=b.marca and e4.cod_inf='PROCCHDED' and p.Grupa_de_munca in ('O') and p.Tip_colab='DAC'
		left outer join extinfop e5 on e5.marca=b.marca and e5.cod_inf='OUG13' and upper(e5.val_inf)='DA' 
		left outer join extinfop e6 on e6.marca=b.marca and e6.cod_inf='OUG6' and upper(e6.val_inf)='DA' 
		left outer join extinfop e7 on e7.marca=b.marca and e7.cod_inf='FALTVENITCASS' and upper(e7.val_inf)='DA' 
		left outer join extinfop e8 on e8.marca=b.marca and e8.cod_inf='EXPATRIATCUA1' and upper(e8.val_inf)='DA' 
		left outer join #Pontaj_marca_locm t on t.data=b.data and t.marca=b.marca and t.loc_de_munca=b.loc_de_munca
		left outer join #Sume_cm_marca m on b.data=m.data and b.marca=m.marca
		left outer join dbo.fNC_tichete (@DataImpTicJ, @DataImpTicS, @marcaJos, 1) ft on @ImpozitTichete=1 and b.Marca=ft.Marca /*and b.Data=ft.Data*/
		left outer join #tipAsigurat a1 on b.data=a1.data and b.marca=a1.marca 
		left outer join #ordinePlafonareCAS op on op.Marca=b.Marca
	group by b.data, b.marca
	order by b.data, OrdinePlafonareCAS, b.marca
	
	open calcnet
	fetch next from calcnet into @Data,@Marca,@SalarDeBaza,@OreCFS,@OreCO,@OreCM,@Invoiri,@Nemotivate,@OreJust,@IndFAMBP,@CMunit,@CMCAS,@Diurna,@SumaImpoz,@ConsAdmin,@SumaImpsep,@AjDeces,
		@Venit_total,@RL,@Locm,@CorQ,@CorT,@CorU,@RetSindicat,@RLpont,@GrpMpont,@Somaj1P,@AsSanP,@TipImpozP,@ProcImpoz,@CheltDed,@GrpMP,@TipcolabP,@AlteSurseP,@GradInvP,
		@TipdedSomajP,@DataAng,@Plecat,@ModAngP,@DataPlecP,@Sind,@DataIcvsom,@DataEcvsom,@NrPersintr,@CNP,@PersNecontractual,@OUG13,@OUG6,@FaraAltVenitPtCASS,@ExpatriatCuA1,
		@BazaCN,@BazaCD,@BazaCS,@Indcmunit19,@Indcmcas19,@Orelunacm,@Indcm,@Indcmcas18,@Zcm18,@Zcm18ant,@BazaCASIant,@BazaCASCMant,@Zcm2341011,
		@Indcm234,@Indcmunit234,@Zcm15,@Zcm8915,@Indcm8915,@Zcm78,@Indcm78,@Indcmsomaj,@Ingrcopsarcina,@zcm_unitate,@zcm_fonduri,@uMarca2CNP,@uMarca2CNPCM,
		@Pensmax_ded,@Pensded_lun,@Pensded_ant,@Pensluna,@SalComp,@AlocHrana,@SomajTehn,@OreST,@SumaNeimp,@ValTichete,@uMarca2CNPSomaj,@tipAsigurat,
		@AvantajeMat,@AvantajeMatImpozabile,@DiurneNeimpoz,@PensieFUnitate,@Part_profit,@SomajTehnicSusp,@OrdinePlafonareCAS,@OreCMSubvSomaj

	While @@fetch_status = 0 
	Begin
		declare @BazaCASCM float,@BazaCASCMCN float,@BazaCASCMCD float,@BazaCASCMCS float,@CASCM float,@CCIFambp float, @OreSomaj int,@ZileCMSusp int,@IndCMSusp float,
		@BazaSomajI float,@SomajI float,@BazaCASSI float,@CASSI float, @CASSFambpsal float,@CASSFambpang float,@BazaCASInd float,@CASInd float,@DifCAS_2CNP int,@VenitDed float,
		@DedBaza decimal(10),@Vennet_in_imp float,@DedPensie float,@VenitBaza float,@Impoz float,@ImpozSep float,@VENIT_NET float,@Impozit float,
		@CASunit float,@CASSunit float,@Somajunit float,@CCI float,@Fambp float,@FondGar float,@ITM float,@Coef_ded int, 
		@DedSomaj float,@BazaCASCN float,@BazaCASCD float,@BazaCASCS float,@vBazaFambp float,@vBazaFambpCM float

		Select @SomajI=0,@BazaSomajI=0,@OreSomaj=0,@BazaCASCM=0,@CASCM=0,@CCIFambp=0,@ZileCMsusp=0,@IndCMsusp=0,@BazaCASSI=0,@CASSI=0,@BazaCASInd=0,@CASInd=0,
		@Vennet_in_imp=0,@DedBaza=0,@VenitDed=0,@DedPensie=0,@VenitBaza=0,@Impozit=0,@ImpozSep=0,@Venit_net=0,@DedSomaj=0,@vBazaFambp=0,@vBazaFambpCM=0

--	pozitia cu ultima zi din luna
		update net set Venit_total=0,VENIT_NET=0,Impozit=0,Rest_de_plata=0,Asig_sanatate_din_net=0,Pensie_suplimentara_3=0,Somaj_1=0,Asig_sanatate_din_impozit=0,Asig_sanatate_din_CAS=0,
			Coef_tot_ded=0,VEN_NET_IN_IMP=0,Ded_baza=0,Ded_suplim=0,VENIT_BAZA=0,Chelt_prof=0,Debite_externe=0,Rate=0,Debite_interne=0,Cont_curent=0,
			CAS=0,Somaj_5=0,Fond_de_risc_1=0,Camera_de_munca_1=0,Asig_sanatate_pl_unitate=0,Baza_CAS=0
		where Data=@dataSus and (@Marca='' or Marca=@Marca)
--	pozitia cu prima zi din luna	
		update net set Somaj_5=0,Ded_baza=0,Ded_suplim=0 
		where Data=@dataJos and (@Marca='' or Marca=@Marca)

--	calcul asigurari angajat
		exec psCalcul_asigurari_angajat 
			@dataJos,@dataSus,@Marca,@Inversare,@Salar_minim,@Salar_mediu,@OreLuna,@pCASind,@pCASSind, @pSomajind, @pSomajI,@pCASgr3,@pCASgr2,@pCASgr1,@pCCI,@CoefCAS,
			@CompSalarnet,@SalarNetValuta,@SalarNetFCM,@NuCAS_H,@NuCASS_H, @CASSimps_K,@Somaj_K,@NuASS_J,@CAS_J,@NuASSA_N,@CAS_U,@Dafora,@Pasmatex,
			@OreCFS,@Invoiri,@Nemotivate, @OreJust,@IndFAMBP,@CMUnit,@CMcas,@Diurna,@SumaImpoz,@ConsAdmin,@Venit_total,
			@RL,@CorT,@CorU,@GrpMpont,@Somaj1P,@AsSanP,@GrpMP,@TipColabP,@TipdedSomajP,@CheltDed,
			@BazaCN,@BazaCD,@BazaCS, @Indcmunit19,@Indcmcas19,@Orelunacm,@Indcm,@Zcm18,@Zcm18ant,@BazaCASIant,@BazaCASCMant,
			@Zcm2341011, @Indcmunit234,@Zcm15,@Zcm78,@Indcm78,@Indcmsomaj,@Zcm_unitate,@Zcm_fonduri,
			@uMarca2CNP,@uMarca2CNPCM,@uMarca2CNPSomaj,@tipAsigurat,@CNP,@SalComp,@SomajTehn,@OreST,@SumaNeimp,@PensieFUnitate,@SomajTehnicSusp,
			@vBazaFambp output,@vBazaFambpCM output,@TBCASCMCN output,@TBCASCMCD output,@TBCASCMCS output,@TCASCM output,@TBCASSFambpS output,@TCASSFambpS output,
			@TBCASSFambpA output,@TCASSFambpA output, @TBsomajPCON output, @TBsomajPNECON output,@TSomaj output,
			@TBCCIFambp output,@TCCIFambp output,@SomajI output,@BazaSomajI output,@BazaCASCM output,@CASCM output,@CCIFambp output,
			@BazaCASSI output,@CASSI output,@BazaCASInd output,@CASInd output,@BazaCASCMCN output,@BazaCASCMCD output,@BazaCASCMCS output,
			@BazaCASCN output,@BazaCASCD output,@BazaCASCS output,@CASSFambpsal output,@CASSFambpang output, @OUG13, @AlteSurseP, @OrdinePlafonareCAS, @lmCorectie, 
			@FaraAltVenitPtCASS

--	calcul impozit, deducere personala, venit net
		exec psCalcul_impozit_vennet
			@dataJos,@dataSus,@Marca,@SalarDeBaza,@Salar_minim,@Salar_mediu,@IndRefSomaj,@OreLuna,@Sindicat_procentual,@procent_sindicat,@pCASind,@Buget,@NuRotBI,@ChindPont,
			@ChindLunacrt,@Chindvnet,@NuCASS_H,@Imps_H,@NuASS_N,@CorU_RP,@CAS_U,@ImpozitNegativ,@Tichete,@NuDPSH,@AdVenNet_Q,@VenitBrutCuded,@VenitBrutFaraDed,
			@Dafora,@Drumor,@OreCFS,@OreCMSubvSomaj,@OreCO,@Invoiri,@Nemotivate,@OreJust,@SumaImpoz,@SumaImpsep,@ConsAdmin,@Venit_total,@RL,@CorU,@RetSindicat,
			@RLpont,@AsSanP,@TipImpozP,@ProcImpoz,@GrpMP,@TipColabP,@GradInvP,@TipdedSomajP,@Orelunacm,@SomajTehn,@OreST,
			@SumaNeimp,@ValTichete,@SomajI output,@CASSI output,@CASInd output,@Vennet_in_imp output,@DedBaza output,
			@DedPensie output,@VenitBaza output,@Impozit output,@ImpozSep output,@Venit_net output,@DedSomaj output, 
			@DataAng,@Plecat,@ModAngP,@DataPlecP,@DataEcvsom,@DataIcvsom,@NrPersintr,@Zcm8915,@Indcm8915,
			@PersNecontractual,@Pensmax_ded,@Pensded_lun,@Pensded_ant,@Pensluna,@AvantajeMat,@AvantajeMatImpozabile,@DiurneNeimpoz

--	calcul contributii unitate
		exec psCalcul_contributii_unitate 
			@dataJos,@dataSus,@Marca,@Locm,@Salar_minim,@pCASgr1,@pCASgr2,@pCASgr3,@pCCI,@CoefCCI,@pCASSU,@pSomajU,
			@pFondGar,@pFambp,@CalculITM,@pITM,@InstPubl,@CASScolab,@NuITMcolab,@NuITMpens,@SomajColab,
			@CCIcolabO,@CCIcolabP,@NuCAS_H,@NuCASS_H,@CASSimps_K,@CCI_K,@CorU_RP,@CAS_U,@Pasmatex,@Plastidr,
			@IndFAMBP,@CMCAS,@SumaImpoz,@ConsAdmin,@AjDeces,@Venit_total,@CorU,@Somaj1P,@AsSanP,@GrpMP,@TipColabP,@AlteSurseP,@GradInvP,@TipdedSomajP,
			@OUG13,@OUG6,@ExpatriatCuA1,@Indcmcas19,@Coef_ded,@SalComp,@AlocHrana,@SomajTehn,@BazaCASCMCN,@BazaCASCMCD,@BazaCASCMCS,@CASCM,@CCIFambp,@BazaSomajI,@SomajI,
			@BazaCASSI,@CASSI,@CASSFambpsal,@CASSFambpang,@BazaCASInd,@CASInd,@DedBaza,@Vennet_in_imp,@DedPensie,@VenitBaza,@Impozit,@ImpozSep,@Venit_net,@DedSomaj,@Part_profit,
			@BazaCASCN,@BazaCASCD,@BazaCASCS,@vBazaFambp,@vBazaFambpCM,@TBCASCN output,@TBCASCD output,@TBCASCS output,@TCAS output,
			@TBCASS output,@TCASS output,@TBSomajPCON output,@TBSomajPNECON output,@TSomaj output,@TBCCI output,
			@TCCI output,@TBFambp output,@TFambp output,@TBFG output,@TFG output,@TBITM output,@TITM output

		fetch next from calcnet into @Data,@Marca,@SalarDeBaza,@OreCFS,@OreCO,@OreCM,@Invoiri,@Nemotivate,@OreJust,@IndFAMBP,@CMunit,@CMCAS,@Diurna,@SumaImpoz,@ConsAdmin,@SumaImpsep,@AjDeces,
		@Venit_total,@RL,@Locm,@CorQ,@CorT,@CorU,@RetSindicat,@RLpont,@GrpMpont,@Somaj1P,@AsSanP,@TipImpozP,@ProcImpoz,@CheltDed,@GrpMP,@TipcolabP,@AlteSurseP,@GradInvP,
		@TipdedSomajP,@DataAng,@Plecat,@ModAngP,@DataPlecP,@Sind,@DataIcvsom,@DataEcvsom,@NrPersintr,@CNP,@PersNecontractual,@OUG13,@OUG6,@FaraAltVenitPtCASS,@ExpatriatCuA1,
		@BazaCN,@BazaCD,@BazaCS,@Indcmunit19,@Indcmcas19,@Orelunacm,@Indcm,@Indcmcas18,@Zcm18,@Zcm18ant,@BazaCASIant,@BazaCASCMant,@Zcm2341011,
		@Indcm234,@Indcmunit234,@Zcm15,@Zcm8915,@Indcm8915,@Zcm78,@Indcm78,@Indcmsomaj,@Ingrcopsarcina,@zcm_unitate,@zcm_fonduri,@uMarca2CNP,@uMarca2CNPCM,
		@Pensmax_ded,@Pensded_lun,@Pensded_ant,@Pensluna,@SalComp,@AlocHrana,@SomajTehn,@OreST,@SumaNeimp,@ValTichete,@uMarca2CNPSomaj,@tipAsigurat, 
		@AvantajeMat,@AvantajeMatImpozabile,@DiurneNeimpoz,@PensieFUnitate,@Part_profit,@SomajTehnicSusp,@OrdinePlafonareCAS,@OreCMSubvSomaj
	End

	exec psCorectie_contributii @dataJos,@dataSus,@marcaJos,@locmJos,@TBCASCN,@TBCASCD,@TBCASCS,@TCAS,@TBCASCMCN,@TBCASCMCD,@TBCASCMCS,@TCASCM,@TBsomajPCON,@TBsomajPNECON,@TSomaj,
		@TBCASS,@TCASS,@TBCASSFambpS,@TCASSFambpS,@TBCASSFambpA,@TCASSFambpA,@TBFambp,@TFambp,@TBITM,@TITM,@TBCCI,@TCCI,@TBCCIFambp,@TCCIFambp,@TBFG,@TFG,0,0,@lmCorectie

	if object_id('tempdb..#ordinePlafonareCAS') is not null drop table #ordinePlafonareCAS
	if object_id('tempdb..#tipAsigurat') is not null drop table #tipAsigurat
	if object_id('tempdb..#pontaj_marca_locm') is not null drop table #pontaj_marca_locm
	if object_id('tempdb..#Sume_cm_marca') is not null drop table #Sume_cm_marca
	if object_id('tempdb..#brut') is not null drop table #brut
	if object_id('tempdb..#personal') is not null drop table #personal
		
	close calcnet
	Deallocate calcnet
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCalcul_venit_net (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
