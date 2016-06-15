--***
/**	functie istoric CO	*/
Create
function [dbo].[istoric_co] 
	(@Datajos datetime, @Datasus datetime, @lLocm int, @pLocm char(9), @lStrict int, @lMarca int, @pMarca char(6),
	@lCod_functie int, @pCod_functie char(6), @lLocm_statie int, @pLocm_statie char(9), @lGrupa_munca int, @cGrupa_munca char(1), @lGrupa_exceptata int, @lTipstat int, @pTipstat char(10), @Ordonare_locm char(2), @Alfabetic int, @Istoric_co_pt_zile_co_ramase int, @Zile_ramase_fct_cuvenite_la_luna int)
returns @istoric_co table
	(Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Denumire_lm char(30), Zile_CO int, Indemnizatie_co float, Baza_calcul_3 float, Baza_calcul_2 float, Baza_calcul_1 float, Zile_calcul_3 float, Zile_calcul_2 float, Zile_calcul_1 float,
	Baza_calcul_luna float, Zile_calcul_luna int, Media_luna_curenta float, Media_ultimelor_3_luni float, Medie_zilnica_CO float, Indemnizatie_co_an float, Ordonare char(100), Total_procent float)
as
begin
	declare @Spv_co bit,@Spfs_co bit,@Spspec_co bit,@Spspp bit,@Indcond_co bit,@Sp1_co bit,@Sp2_co bit,@Sp3_co bit, @Sp4_co bit,@Sp5_co bit,@Sp6_co bit,@Sp7_co bit,
	@Spspec_suma bit,@Sp1_suma bit,@Sp2_suma bit,@Sp3_suma bit, @Sp4_suma bit,@Sp5_suma bit,@Sp6_suma bit,@Spfs_suma bit,@Indcond_suma bit, @lProcfix_co bit,@nProcfix_co float, 
	@Suma_comp_co bit,@Suma_comp float, @Spv_indcond bit,@nOre_luna int,@nOre_luna_tura int,@Nrmediu_ore_luna int,
	@nButon_calcul int,@Zile_calcul_co float,@Ore_calcul_co float,@SpElcond bit,@SpDafora bit,@lRegimLV bit,@lBuget bit,
	@Spspec_proc_suma bit,@Baza_spspec float,@Spspec_pers bit,@Spspec_co_baza_suma bit,@Spspec_co_nu_baza_suma bit,
	@nCas_gr3 float, @nCas_indiv float, @nCCI float, @nCASS float, @nSomaj float, @nFond_gar float, @nFambp float, @nITM float, @nProc_chelt float
	
	Set @nCAS_gr3 = dbo.iauParLN(@datasus,'PS','CASGRUPA3')
	Set @nCAS_indiv = dbo.iauParLN(@datasus,'PS','CASINDIV')
	Set @nCCI = dbo.iauParLN(@datasus,'PS','COTACCI')
	Set @nCASS = dbo.iauParLN(@datasus,'PS','CASSUNIT')
	Set @nSomaj = dbo.iauParLN(@datasus,'PS','3.5%SOMAJ')
	Set @nFond_gar = dbo.iauParLN(@datasus,'PS','FONDGAR')
	Set @nFambp = dbo.iauParLN(@datasus,'PS','0.5%ACCM')
	Set @nITM = dbo.iauParLN(@datasus,'PS','1%-CAMERA')
	Set @nProc_chelt=@nCAS_gr3-@nCAS_indiv+@nCCI+@nCASS+@nSomaj+@nFond_gar+@nFambp+@nITM
	Set @Spv_co=dbo.iauParL('PS','CO-SP-V')
	Set @Spfs_co=dbo.iauParL('PS','CO-F-SPL')
	Set @Spspec_co=dbo.iauParL('PS','CO-SPEC')
	Set @Spspp=dbo.iauParL('PS','CO-S-PR')
	Set @Indcond_co=dbo.iauParL('PS','CO-IND')
	Set @Sp1_co=dbo.iauParL('PS','CO-SP1')
	Set @Sp2_co=dbo.iauParL('PS','CO-SP2')
	Set @Sp3_co=dbo.iauParL('PS','CO-SP3')
	Set @Sp4_co=dbo.iauParL('PS','CO-SP4')
	Set @Sp5_co=dbo.iauParL('PS','CO-SP5')
	Set @Sp6_co=dbo.iauParL('PS','CO-SP6')
	Set @Sp7_co=dbo.iauParL('PS','CO-SP7')
	Set @Spspec_suma=dbo.iauParL('PS','SSP-SUMA')
	Set @Sp1_suma=dbo.iauParL('PS','SC1-SUMA')
	Set @Sp2_suma=dbo.iauParL('PS','SC2-SUMA')
	Set @Sp3_suma=dbo.iauParL('PS','SC3-SUMA')
	Set @Sp4_suma=dbo.iauParL('PS','SC4-SUMA')
	Set @Sp5_suma=dbo.iauParL('PS','SC5-SUMA')
	Set @Sp6_suma=dbo.iauParL('PS','SC6-SUMA')
	Set @Spfs_suma=dbo.iauParL('PS','SPFS-SUMA')
	Set @Indcond_suma=dbo.iauParL('PS','INDC-SUMA')
	Set @lProcfix_co=dbo.iauParL('PS','CO-SPFIX')
	Set @nProcfix_co=dbo.iauParN('PS','CO-SPFIX')
	Set @Suma_comp=(case when dbo.iauParL('PS','CO-COMP')=1 then dbo.iauParN('PS','SUMACOMP') else 0 end)
	Set @Spv_indcond=dbo.iauParL('PS','SP-V-INDC')
	Set @nOre_luna=(case when dbo.iauParLN(@Datasus,'PS','ORE_LUNA')=0 then dbo.iauParN('PS','ORE_LUNA') else dbo.iauParLN(@Datasus,'PS','ORE_LUNA') end)
	Set @nOre_luna_tura=dbo.iauParN('PS','ORET_LUNA')
	Set @Nrmediu_ore_luna=(case when dbo.iauParLN(@Datasus,'PS','NRMEDOL')=0 then dbo.iauParN('PS','NRMEDOL') else dbo.iauParLN(@Datasus,'PS','NRMEDOL') end)
	Set @nButon_calcul=dbo.iauParN('PS','CALCUL-CO')
	Set @Zile_calcul_co=dbo.iauParN('PS','CO-NRZILE')
	Set @Ore_calcul_co=(case when @nButon_calcul=1 then 8*@Zile_calcul_co when @nButon_calcul=2 then @nOre_luna else @Nrmediu_ore_luna end)
	Set @Spspec_proc_suma=dbo.iauParL('PS','SSPEC')
	Set @Baza_spspec=dbo.iauParN('PS','SSPEC')
	Set @Spspec_pers=(case when @Spspec_co=1 and @Spspec_proc_suma=0 and @Spspec_suma=0 then 1 else 0 end)
	Set @Spspec_co_baza_suma=(case when @Spspec_co=1 and @Spspec_proc_suma=1 then 1 else 0 end)
	Set @Spspec_co_nu_baza_suma=(case when @Spspec_co=1 and @Spspec_proc_suma=0 then 1 else 0 end)
	Set @lRegimLV=dbo.iauParL('PS','REGIMLV')
	Set @lBuget=dbo.iauParL('PS','UNITBUGET')
	Set @SpElcond=dbo.iauParL('SP','ELCOND')
	Set @SpDafora=dbo.iauParL('SP','DAFORA')

	insert into @istoric_co
	select Data, Marca, Nume, Loc_de_munca, Denumire_lm, Zile_CO, 
	(case when @Istoric_co_pt_zile_co_ramase=1 then 
	(case when Zile_CO<0 and Zile_co_efectuat_an<>0 then round(Zile_CO*Indemnizatie_co_an/Zile_co_efectuat_an,0) else 
	round((case when Zile_calcul_3+Zile_calcul_2+Zile_calcul_1<>0 and  round((Baza_calcul_3+Baza_calcul_2+Baza_calcul_1)/(Zile_calcul_3+Zile_calcul_2+Zile_calcul_1),3)> round(Baza_calcul_luna/Zile_calcul_luna,3) then round((Baza_calcul_3+Baza_calcul_2+Baza_calcul_1)/(Zile_calcul_3+Zile_calcul_2+Zile_calcul_1),3) else round(Baza_calcul_luna/Zile_calcul_luna,3) end)*Zile_CO,0) end) else Indemnizatie_co end), 
	Baza_calcul_3, Baza_calcul_2, Baza_calcul_1, Zile_calcul_3, Zile_calcul_2, Zile_calcul_1, Baza_calcul_luna, Zile_calcul_luna, round(Baza_calcul_luna/Zile_calcul_luna,3), (case when Zile_calcul_3+Zile_calcul_2+Zile_calcul_1<>0 then  round((Baza_calcul_3+Baza_calcul_2+Baza_calcul_1)/(Zile_calcul_3+Zile_calcul_2+Zile_calcul_1),3) else 0 end), 
	(case when Zile_calcul_3+Zile_calcul_2+Zile_calcul_1<>0 and round((Baza_calcul_3+Baza_calcul_2+Baza_calcul_1)/(Zile_calcul_3+Zile_calcul_2+Zile_calcul_1),3)> round(Baza_calcul_luna/Zile_calcul_luna,3) then round((Baza_calcul_3+Baza_calcul_2+Baza_calcul_1)/(Zile_calcul_3+Zile_calcul_2+Zile_calcul_1),3) else round(Baza_calcul_luna/Zile_calcul_luna,3) end), Indemnizatie_co_an, Ordonare,@nProc_chelt
	from dbo.fPSFormare_istoric_co (@Datajos, @Datasus, @lLocm, @pLocm, @lStrict, @lMarca ,@pMarca, @lCod_functie, @pCod_functie, @lLocm_statie, @pLocm_statie, @lGrupa_munca, @cGrupa_munca, @lGrupa_exceptata, @lTipstat, @pTipstat, 
	@Ordonare_locm, @Alfabetic, @Istoric_co_pt_zile_co_ramase,  @Zile_ramase_fct_cuvenite_la_luna, 
	@Spv_co, @Spfs_co, @Spspec_co, @Spspp, @Indcond_co, @Sp1_co, @Sp2_co, @Sp3_co, @Sp4_co, @Sp5_co, @Sp6_co, @Sp7_co, 
	@Spspec_suma, @Sp1_suma, @Sp2_suma, @Sp3_suma, @Sp4_suma, @Sp5_suma, @Sp6_suma, @Spfs_suma, @Indcond_suma, @lProcfix_co, @nProcfix_co, @Suma_comp_co, @Suma_comp, @Spv_indcond, 
	@nOre_luna, @nOre_luna_tura, @Nrmediu_ore_luna,@nButon_calcul, @Zile_calcul_co, @Ore_calcul_co, @SpElcond, @SpDafora, @lRegimLV, @lBuget,
	@Spspec_proc_suma, @Baza_spspec, @Spspec_pers, @Spspec_co_baza_suma, @Spspec_co_nu_baza_suma)
	order by ordonare,(case when @Alfabetic=1 then nume else marca end)

	return
end
