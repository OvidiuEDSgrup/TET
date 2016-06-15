--***
/**	proc. calcul contributii	*/
Create
procedure  [dbo].[psCalcul_contributii] 
@DataJ datetime,@DataS datetime,@MarcaJ char(6),@LocmJ char(9),@Inversare int,@Salmin float,@Salmed float,
@RefSomaj float, @OreLuna int, @SindProc int,@ProcSind float,@pCASind float,@pCASSind float,@pSomajind float,@pSomajI float,
@pCASgr3 float, @pCASgr2 float, @pCASgr1 float,@pCCI float,@CoefCAS float,@CoefCCI float,@pCASSU float,
@pSomajU float,@pFondGar float, @pFambp float, @CalculITM int,@pITM float,@Buget int,@InstPubl int,@CASSColab int,@NuITMcolab int,@NuITMpens int, 
@Somajcolab int, @CCIcolabP int,@CCIcolabO int,@Chindpont int,@Chindlcrt int,@Chindvnet int,@NuRotBI int,
@CompSalnet int, @SalNetValuta int, @SalNetFCM int, @NuCAS_H int,@NuCASS_H int,@Imps_H int,@CASSimps_K int,
@Somaj_K int,@CCI_K int,@NuASS_J int,@CAS_J int, @NuASS_N int, @NuASSA_N int,@CorU_RP int,@CAS_U int,
@VBcuded float,@VBfaraded float,@Dafora int,@Pasmatex int,@Drumor int,@Plastidr int,
@Data datetime,@Marca char(6),@OreCFS int,@OreCO int,@OreCM int,@Invoiri int,@Nemotivate int,@OreJust int,
@IndFAMBP float, @CMunit float,@CMcas float,@Diurna float,@SumaImpoz float,@ConsAdmin float,@SumaImpsep float, 
@AjDeces float,@Venit_total float,@RL float,@Locm char(9),@CorQ float,@CorT float,@CorU float,@RetSindicat float,
@RLpont float, @RLbrut float,@GrpMpont char(1), @Somaj1P int,@AsSanP float,@TipImpozP char(1),@ProcImpoz int,@CheltDed decimal(10),@GrpMP char(1),@TipcolabP char(3),
@AlteSurseP char(1),@GradInvP char(1),@TipdedSomajP float,@DataAng datetime,@Plecat char(1),@ModAngP char(1),
@DataPlecP datetime,@Sind char(1),@DataIcvsom datetime,@DataEcvsom datetime,@NrPersintr int,@BazaCN float,@BazaCD float,@BazaCS float,
@Indcmunit19 float,@Indcmcas19 float,@Orelunacm int,@Indcm float,@Indcmcas18 float,@Zcm18 int,@Zcm18ant int,
@BazaCASIant float,@BazaCASCMant float,@Zcm2341011 int,@Indcm234 float,@Indcmunit234 float,@Zcm15 int,@Zcm8915 int, 
@Indcm8915 float,@Zcm78 int,@Indcm78 float,@Indcmsomaj float,@Ingrcopsarcina int,@Zcm_unitate int,@Zcm_fonduri int,
@PersNecontractual char(1),@OUG13 int,@OUG6 int,@uMarca2CNP int, @uMarca2CNPCM int,@CNP char(13),@Pensmax_ded float,@Pensded_lun float,@Pensded_ant float,@Pensluna float,
@SalComp float,@AlocHrana float,@SomajTehn float,@OreST int,@SumaNeimp float, @ValTichete float,@uMarca2CNPSomaj int,@AvantajeMat float,@PensieFUnitate float,
@TBCASCN decimal(12,2) output,@TBCASCD decimal(12,2) output,@TBCASCS decimal(12,2) output,@TCAS decimal(12,2) output,
@TBCASCMCN decimal(12,2) output,@TBCASCMCD decimal(12,2) output,@TBCASCMCS decimal(12,2) output,
@TCASCM decimal(12,2) output,@TBCASS decimal(12,2) output,@TCASS decimal(12,2) output,@TBCASSFambpS decimal(12,2) output, 
@TCASSFambpS decimal(12,2) output,@TBCASSFambpA decimal(12,2) output,@TCASSFambpA decimal(12,2) output,
@TBsomajPCON decimal(12,2) output,@TBsomajPNECON decimal(12,2) output,@TSomaj decimal(12,2) output,
@TBCCI decimal(12,2) output,@TCCI decimal(12,2) output,@TBCCIFambp decimal(12,2) output,@TCCIFambp decimal(12,2) output,
@TBFambp decimal(12,2) output,@TFambp decimal(12,2) output,@TBFG decimal(12,2) output,@TFG decimal(12,2) output,
@TBITM decimal(12,2) output,@TITM decimal(12,2) output
As
Begin
declare @BazaCASCM float,@BazaCASCMCN float,@BazaCASCMCD float,@BazaCASCMCS float,@CASCM float,@CCIFambp float, @OreSomaj int,@ZileCMSusp int,@IndCMSusp float,@BazaSomajI float,@SomajI float,@BazaCASSI float,@CASSI float,
@CASSFambpsal float,@CASSFambpang float,@BazaCASInd float,@CASInd float,@DifCAS_2CNP int,@VenitDed float,
@DedBaza decimal(10),@Vennet_in_imp float,@DedPensie float,@VenitBaza float,@Impoz float,@ImpozSep float,@VENIT_NET float,@Impozit float,
@CASunit float,@CASSunit float,@Somajunit float,@CCI float,@Fambp float,@FondGar float,@ITM float,@Coef_ded int, 
@DedSomaj float,@BazaCASCN float,@BazaCASCD float,@BazaCASCS float,@vBazaFambp float,@vBazaFambpCM float
exec psAnulare_net @DataJ,@DataS,@Marca
Select @SomajI=0,@BazaSomajI=0,@OreSomaj=0,@BazaCASCM=0,@CASCM=0,@CCIFambp=0,@ZileCMsusp=0,@IndCMsusp=0,
@BazaCASSI=0,@CASSI=0,@BazaCASInd=0,@CASInd=0,@Vennet_in_imp=0,@DedBaza=0,@VenitDed=0,@DedPensie=0,
@VenitBaza=0,@Impozit=0,@ImpozSep=0,@Venit_net=0,@DedSomaj=0,@vBazaFambp=0,@vBazaFambpCM=0
exec psCalcul_asigurari_angajat @DataJ,@DataS,@Marca,@Inversare,@Salmin,@Salmed,@OreLuna,@pCASind,@pCASSind, @pSomajind, @pSomajI,@pCASgr3,@pCASgr2,@pCASgr1,@pCCI,@CoefCAS,@CompSalnet,@SalNetValuta,@SalNetFCM,@NuCAS_H,@NuCASS_H, @CASSimps_K,@Somaj_K,@NuASS_J,@CAS_J,@NuASSA_N,@CAS_U,@Dafora,@Pasmatex,
@OreCFS,@Invoiri,@Nemotivate, @OreJust,@IndFAMBP,@CMUnit,@CMcas,@Diurna,@SumaImpoz,@ConsAdmin,@Venit_total,@RL,@CorT,@CorU,@GrpMpont,@Somaj1P,@AsSanP,@GrpMP,@TipColabP,@TipdedSomajP,@CheltDed,
@BazaCN,@BazaCD,@BazaCS, @Indcmunit19,@Indcmcas19,@Orelunacm,@Indcm,@Zcm18,@Zcm18ant,@BazaCASIant,@BazaCASCMant,
@Zcm2341011, @Indcmunit234,@Zcm15,@Zcm78,@Indcm78,@Indcmsomaj,@Zcm_unitate,@Zcm_fonduri,
@uMarca2CNP,@uMarca2CNPCM,@uMarca2CNPSomaj,@CNP,@SalComp,@SomajTehn,@OreST,@SumaNeimp,@PensieFUnitate,
@vBazaFambp output,@vBazaFambpCM output,@TBCASCMCN output,@TBCASCMCD output,@TBCASCMCS output,@TCASCM output,@TBCASSFambpS output,@TCASSFambpS output,
@TBCASSFambpA output,@TCASSFambpA output, @TBsomajPCON output, @TBsomajPNECON output,@TSomaj output,
@TBCCIFambp output,@TCCIFambp output,@SomajI output,@BazaSomajI output,@BazaCASCM output,@CASCM output,@CCIFambp output,
@BazaCASSI output,@CASSI output,@BazaCASInd output,@CASInd output,@BazaCASCMCN output,@BazaCASCMCD output,@BazaCASCMCS output,
@BazaCASCN output,@BazaCASCD output,@BazaCASCS output,@CASSFambpsal output,@CASSFambpang output
exec psCalcul_impozit_vennet
@DataJ,@DataS,@Marca,@Salmin,@RefSomaj,@OreLuna,@SindProc,@ProcSind,@pCASind,@Buget,@NuRotBI,@ChindPont,
@Chindlcrt,@Chindvnet,@NuCASS_H,@Imps_H,@NuASS_N,@CorU_RP,@CAS_U,@VBcuded,@VBfaraded,@Dafora,@Drumor,
@OreCFS,@OreCM,@OreCO,@Invoiri,@Nemotivate,@OreJust,@SumaImpoz,@SumaImpsep,@ConsAdmin,@Venit_total,@RL,@CorU,@RetSindicat,
@RLpont,@AsSanP,@TipImpozP,@ProcImpoz,@GrpMP,@TipColabP,@GradInvP,@TipdedSomajP,@Orelunacm,@SomajTehn,@OreST,
@SumaNeimp,@ValTichete,@SomajI output,@CASSI output,@CASInd output,@Vennet_in_imp output,@DedBaza output,
@DedPensie output,@VenitBaza output,@Impozit output,@ImpozSep output,@Venit_net output,@DedSomaj output, 
@DataAng,@Plecat,@ModAngP,@DataPlecP,@DataEcvsom,@DataIcvsom,@NrPersintr,@Zcm8915,@Indcm8915,
@PersNecontractual,@Pensmax_ded,@Pensded_lun,@Pensded_ant,@Pensluna,@AvantajeMat
exec psCalcul_contributii_unitate @DataJ,@DataS,@Marca,@Locm,@Salmin,@pCASgr1,@pCASgr2,@pCASgr3,@pCCI,@CoefCCI,@pCASSU,@pSomajU,
@pFondGar,@pFambp,@CalculITM,@pITM,@InstPubl,@CASScolab,@NuITMcolab,@NuITMpens,@SomajColab,
@CCIcolabO,@CCIcolabP,@NuCAS_H,@NuCASS_H,@CASSimps_K,@CCI_K,@CorU_RP,@CAS_U,@Pasmatex,@Plastidr,
@IndFAMBP,@CMCAS,@SumaImpoz,@ConsAdmin,@AjDeces,@Venit_total,@CorU,@Somaj1P,@AsSanP,@GrpMP,@TipColabP,@AlteSurseP,@GradInvP,@TipdedSomajP,
@OUG13,@OUG6,@Indcmcas19,@Coef_ded,@SalComp,@AlocHrana,@SomajTehn,@BazaCASCMCN,@BazaCASCMCD,@BazaCASCMCS,@CASCM,@CCIFambp,@BazaSomajI,@SomajI,
@BazaCASSI,@CASSI,@CASSFambpsal,@CASSFambpang,@BazaCASInd,@CASInd,@DedBaza,@Vennet_in_imp,@DedPensie,@VenitBaza,@Impozit,@ImpozSep,@Venit_net,@DedSomaj,
@BazaCASCN,@BazaCASCD,@BazaCASCS,@vBazaFambp,@vBazaFambpCM,@TBCASCN output,@TBCASCD output,@TBCASCS output,@TCAS output,
@TBCASS output,@TCASS output,@TBSomajPCON output,@TBSomajPNECON output,@TSomaj output,@TBCCI output,
@TCCI output,@TBFambp output,@TFambp output,@TBFG output,@TFG output,@TBITM output,@TITM output
End
