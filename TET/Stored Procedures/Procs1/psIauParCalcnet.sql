--***
/**	proc. iauParcalcnet	*/
Create
procedure  [dbo].[psIauParCalcnet] 
@DataS datetime, @HostID char(8) output,@Salar_minim float output,@Salar_mediu float output,@Indref_somaj float output,
@Ore_luna int output,@Sind_proc int output,@Proc_sind float output,@pCAS_ind float output,@pCASS_ind float output,
@pSomaj_ind float output,@pSomajI float output,@pCAS_gr3 float output,@pCAS_gr2 float output,@pCAS_gr1 float output,
@pCCI float output,@Coef_CAS float output, @Coef_CCI float output,@pCASSU float output,@pSomajU float output,
@pFond_gar float output,@pFambp float output,@Calcul_ITM int output,@pITM float output,
@Buget int output,@Inst_publ int output, @CASS_colab int output,@NuITM_colab int output, @NuITM_pens int output,
@Somaj_colab int output,@CCI_colabP int output, @CCI_colabO int output,@Chind_pont int output, 
@Chind_lunacrt int output,@Chind_vnet int output,@NuRoT_BI int output, @Comp_sal_net int output,
@Salar_net_valuta int output,@NuCAS_H int output,@NuCASS_H int output,@Imps_H int output, @CASSimps_K int output,@Somaj_K int output,@CCI_K int output,
@NuASS_J int output, @CAS_J int output,@NuASS_N int output,@NuASSA_N int output, 
@CorU_RP int output,@CAS_U int output,@Venit_brut_cu_ded float output,@Venit_brut_fara_ded float output,
@Dafora int output, @Pasmatex int output,@Drumor int output, @Plastidr int output
As
Begin
Set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
Set @Salar_minim=dbo.iauParLN(@DataS,'PS','S-MIN-BR')
Set @Salar_mediu=dbo.iauParLN(@DataS,'PS','SALMBRUT')
Set @Indref_somaj=dbo.iauParLN(@DataS,'PS','SOMAJ-ISR')
Set @Ore_luna=dbo.iauParLN(@DataS,'PS','ORE_LUNA')
Exec Luare_date_par 'PS','SIND%',@Sind_proc OUTPUT,@Proc_sind OUTPUT,''
Set @pCAS_ind=dbo.iauParLN(@DataS,'PS','CASINDIV')
Set @pCASS_ind=dbo.iauParLN(@DataS,'PS','CASSIND')
Set @pSomaj_ind=dbo.iauParLN(@DataS,'PS','SOMAJIND')
Set @pCAS_gr3=dbo.iauParLN(@DataS,'PS','CASGRUPA3')-dbo.iauParLN(@DataS,'PS','CASINDIV')
Set @pCAS_gr2=dbo.iauParLN(@DataS,'PS','CASGRUPA2')-dbo.iauParLN(@DataS,'PS','CASINDIV')
Set @pCAS_gr1=dbo.iauParLN(@DataS,'PS','CASGRUPA1')-dbo.iauParLN(@DataS,'PS','CASINDIV')
Set @pCCI=dbo.iauParLN(@DataS,'PS','COTACCI')
Set @Coef_CAS=dbo.iauParN('PS','COEFCAS')
Set @Coef_CAS=@Coef_CAS/1000000
Set @Coef_CCI=dbo.iauParN('PS','COEFCCI')
Set @Coef_CCI=@Coef_CCI/1000000
Set @pCASSU=dbo.iauParLN(@DataS,'PS','CASSUNIT')
Set @pSomajU=dbo.iauParLN(@DataS,'PS','3.5%SOMAJ')
Set @pFond_gar=dbo.iauParLN(@DataS,'PS','FONDGAR')
Set @pFambp=dbo.iauParLN(@DataS,'PS','0.5%ACCM')
Set @Calcul_ITM=dbo.iauParL('PS','1%-CAMERA')
Set @pITM=dbo.iauParLN(@DataS,'PS','1%-CAMERA')
Set @Buget=dbo.iauParL('PS','UNITBUGET')
Set @Inst_publ=dbo.iauParL('PS','INSTPUBL')
Set @CASS_colab=dbo.iauParL('PS','CALFASC')
Set @NuITM_colab=dbo.iauParL('PS','NCALPCMC')
Set @NuITM_pens=dbo.iauParL('PS','NCALPCMPE')
Set @Somaj_colab=dbo.iauParL('PS','CAL5FR1')
Set @CCI_colabP=dbo.iauParL('PS','CCICOLAB')
Set @CCI_colabO=dbo.iauParL('PS','CCICOLABO')
Set @Chind_pont=dbo.iauParL('PS','CHINDPON')
Set @Chind_lunacrt=dbo.iauParL('PS','CHINDLCRT')
Set @Chind_vnet=dbo.iauParL('PS','CHINDVEN')
Set @NuRoT_BI=dbo.iauParL('PS','BAZANEROT')
Set @Comp_sal_net=dbo.iauParL('PS','COMPSALN')
Set @Salar_net_valuta=dbo.iauParL('PS','SALNETV')
Set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
Set @NuCASS_H=dbo.iauParL('PS','NUASS-H')
Set @Imps_H=dbo.iauParL('PS','IMPSEP-H')
Set @NuASS_J=dbo.iauParL('PS','NUASS-J')
Set @CAS_J=dbo.iauParL('PS','CAS-J')
Set @CASSimps_K=dbo.iauParL('PS','ASSIMPS-K')
Set @Somaj_K=dbo.iauParL('PS','SOMAJ-K')
Set @CCI_K=dbo.iauParL('PS','CCI-K')
Set @NuASS_N=dbo.iauParL('PS','NUASS-N')
Set @NuASSA_N=dbo.iauParL('PS','NUASSA-N')
Set @CorU_RP=dbo.iauParL('PS','ADRPL-U')
Set @CAS_U=dbo.iauParL('PS','CALCAS-U')
Set @Venit_brut_cu_ded=dbo.iauParN('PS','VBCUDEDP')
Set @Venit_brut_fara_ded=dbo.iauParN('PS','VBFDEDP')
Set @Dafora=dbo.iauParL('SP','DAFORA')
Set @Pasmatex=dbo.iauParL('SP','PASMATEX')
Set @Drumor=dbo.iauParL('SP','DRUMOR')
Set @Plastidr=dbo.iauParL('SP','PLASTIDR')
End
