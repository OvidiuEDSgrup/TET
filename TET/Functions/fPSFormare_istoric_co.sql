--***
/**	functie pentru selectie istoric CO */
Create
function [dbo].[fPSFormare_istoric_co] (@Datajos datetime, @Datasus datetime, @lLocm bit, @pLocm char(9), @lStrict bit, 
@lMarca bit, @pMarca char(6), @lCod_functie bit, @pCod_functie char(6), @lLocm_statie bit, @pLocm_statie char(9), 
@lGrupa_munca int, @cGrupa_munca char(1), @lGrupa_exceptata int, @lTipstat bit, @pTipstat char(10), @Ordonare_locm char(2), @Alfabetic bit, @Istoric_co_pt_zile_co_ramase bit, @Zile_ramase_fct_cuvenite_la_luna int, 
@Spv_co bit,@Spfs_co bit,@Spspec_co bit,@Spspp bit,@Indcond_co bit,@Sp1_co bit,@Sp2_co bit,@Sp3_co bit, @Sp4_co bit,@Sp5_co bit,@Sp6_co bit,@Sp7_co bit,@Spspec_suma bit,@Sp1_suma bit,@Sp2_suma bit,@Sp3_suma bit, @Sp4_suma bit,@Sp5_suma bit,@Sp6_suma bit,@Spfs_suma bit,@Indcond_suma bit, @lProcfix_co bit,@nProcfix_co float, @Suma_comp_co bit,@Suma_comp float, @Spv_indcond bit,@nOre_luna int,@nOre_luna_tura int,@Nrmediu_ore_luna int,
@nButon_calcul int,@Zile_calcul_co float,@Ore_calcul_co float,@SpElcond bit,@SpDafora bit,@lRegimLV bit,@lBuget bit,
@Spspec_proc_suma bit,@Baza_spspec float,@Spspec_pers bit,@Spspec_co_baza_suma bit,@Spspec_co_nu_baza_suma bit)
returns @formare_istoric_co table
(Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Denumire_lm char(30), Zile_CO int, Indemnizatie_co float, Baza_calcul_3 float, Baza_calcul_2 float, Baza_calcul_1 float, Zile_calcul_3 float, Zile_calcul_2 float, Zile_calcul_1 float,
Baza_calcul_luna float, Zile_calcul_luna int, Indemnizatie_co_an float, Zile_co_efectuat_an int, Ordonare char(100))
as
begin
insert into @formare_istoric_co
select a.Data, a.marca as marca, max(isnull(p.Nume,b.Nume)),max(isnull(p.Loc_de_munca,b.Loc_de_munca)),max(c.denumire), sum(a.Zile_co), sum(a.Indemnizatie_co),
round((select sum(round(ind_regim_normal,0)+@Spv_co*r.spor_vechime+@Spfs_co*r.spor_de_functie_suplimentara+ @Spspec_co*r.spor_specific+@Spspp*r.spor_sistematic_peste_program+@Indcond_co*r.ind_nemotivate+@Sp1_co*r.spor_cond_1+ @Sp2_co*r.spor_cond_2+@Sp3_co*r.spor_cond_3+@Sp4_co*r.spor_cond_4+@Sp5_co*r.spor_cond_5+@Sp6_co*r.spor_cond_6+ @Sp7_co*r.spor_cond_7+r.ind_obligatii_cetatenesti+(case when @SpElcond=0 then r.ind_concediu_de_odihna else 0 end)) from brut r where r.data = dbo.eom(dateadd(month,-3,a.Data)) and r.marca = a.marca),0) as suma_luna_3,
round((select sum(round(ind_regim_normal,0)+@Spv_co*r.spor_vechime+@Spfs_co*r.spor_de_functie_suplimentara+ @Spspec_co*r.spor_specific+@Spspp*r.spor_sistematic_peste_program+@Indcond_co*r.ind_nemotivate+@Sp1_co*r.spor_cond_1+ @Sp2_co*r.spor_cond_2+@Sp3_co*r.spor_cond_3+@Sp4_co*r.spor_cond_4+@Sp5_co*r.spor_cond_5+@Sp6_co*r.spor_cond_6+ @Sp7_co*r.spor_cond_7+r.ind_obligatii_cetatenesti+(case when @SpElcond=0 then r.ind_concediu_de_odihna else 0 end)) from brut r where r.data = dbo.eom(dateadd(month,-2,a.Data)) and r.marca = a.marca),0) as suma_luna_2,
round((select sum(round(ind_regim_normal,0)+@Spv_co*r.spor_vechime+@Spfs_co*r.spor_de_functie_suplimentara+ @Spspec_co*r.spor_specific+@Spspp*r.spor_sistematic_peste_program+@Indcond_co*r.ind_nemotivate+@Sp1_co*r.spor_cond_1+ @Sp2_co*r.spor_cond_2+@Sp3_co*r.spor_cond_3+@Sp4_co*r.spor_cond_4+@Sp5_co*r.spor_cond_5+@Sp6_co*r.spor_cond_6+ @Sp7_co*r.spor_cond_7+r.ind_obligatii_cetatenesti+(case when @SpElcond=0 then r.ind_concediu_de_odihna else 0 end)) from brut r where r.data = dbo.eom(dateadd(month,-1,a.Data)) and r.marca = a.marca),0) as suma_luna_1,
(select round(sum((case when (r.ore_lucrate_regim_normal+r.ore_obligatii_cetatenesti+(case when @SpElcond=0 then r.ore_concediu_de_odihna else 0 end))=0 then 1 else (r.ore_lucrate_regim_normal+r.ore_obligatii_cetatenesti+(case when @SpElcond=0 then r.ore_concediu_de_odihna else 0 end)) end)/(case when r.spor_cond_10=0 then 8 else r.spor_cond_10 end)),0) from brut r where r.data = dbo.eom(dateadd(month,-3,a.Data)) and r.marca = a.marca) as zile_luna_3,
(select round(sum((case when (r.ore_lucrate_regim_normal+r.ore_obligatii_cetatenesti+(case when @SpElcond=0 then r.ore_concediu_de_odihna else 0 end))=0 then 1 else (r.ore_lucrate_regim_normal+r.ore_obligatii_cetatenesti+(case when @SpElcond=0 then r.ore_concediu_de_odihna else 0 end)) end)/(case when r.spor_cond_10=0 then 8 else r.spor_cond_10 end)),0) from brut r where r.data = dbo.eom(dateadd(month,-2,a.Data)) and r.marca = a.marca) as zile_luna_2,
(select round(sum((case when (r.ore_lucrate_regim_normal+r.ore_obligatii_cetatenesti+(case when @SpElcond=0 then r.ore_concediu_de_odihna else 0 end))=0 then 1 else (r.ore_lucrate_regim_normal+r.ore_obligatii_cetatenesti+(case when @SpElcond=0 then r.ore_concediu_de_odihna else 0 end)) end)/(case when r.spor_cond_10=0 then 8 else r.spor_cond_10 end)),0) from brut r where r.data = dbo.eom(dateadd(month,-1,a.Data)) and r.marca = a.marca) as zile_luna_1,
round(max(((case when @lBuget=1 then p.salar_de_baza else p.salar_de_incadrare end)*
(100 +@Spv_co*p.spor_vechime+@Spfs_co*(case when @Spfs_suma=1 then 0 else p.spor_de_functie_suplimentara end)+ @Spspec_pers*p.spor_specific+@Spspp*p.spor_sistematic_peste_program+ @Sp1_co*(case when @Sp1_suma=1 then 0 else p.spor_conditii_1 end)+@Sp2_co*(case when @Sp2_suma=1 then 0 else p.spor_conditii_2 end)+ @Sp3_co*(case when @Sp3_suma=1 then 0 else p.spor_conditii_3 end)+ @Sp4_co*(case when @Sp4_suma=1 then 0 else p.spor_conditii_4 end) +
@Sp5_co*(case when @Sp5_suma=1 then 0 else p.spor_conditii_5 end)+@Sp6_co*(case when @Sp6_suma=1 then 0 else p.spor_conditii_6 end)+@Sp7_co*d.spor_cond_7+ 
(case when @Indcond_suma=0 then @Indcond_co*p.indemnizatia_de_conducere else 0 end)+@lProcfix_co*@nProcfix_co)/100+ @Spspec_co_baza_suma*@Baza_spspec*p.spor_specific/100+ @Spspec_co_nu_baza_suma*(case when @Spspec_suma=1 then p.spor_specific else 0 end) +@Spv_co*p.spor_vechime/100*@Spv_indcond*p.indemnizatia_de_conducere*(case when @Indcond_suma=0 then p.salar_de_incadrare/100 else 1 end)+(case when @Indcond_suma=1 then @Indcond_co*p.indemnizatia_de_conducere else 0 end)+@Suma_comp+@Spfs_co*(case when @Spfs_suma=1 then p.spor_de_functie_suplimentara else 0 end) +@Sp1_co*(case when @Sp1_suma=1 then p.spor_conditii_1 else 0 end)+@Sp2_co*(case when @Sp2_suma=1 then p.spor_conditii_2 else 0 end)+@Sp3_co*(case when @Sp3_suma=1 then p.spor_conditii_3 else 0 end)+@Sp4_co*(case when @Sp4_suma=1 then p.spor_conditii_4 else 0 end)+@Sp5_co*(case when @Sp5_suma=1 then p.spor_conditii_5 else 0 end)+@Sp6_co*(case when @Sp6_suma=1 then p.spor_conditii_6 else 0 end))),0) as baza_luna,
(case when @lRegimLV=1 and @nOre_luna_tura<>0 and max(p.salar_lunar_de_baza)<>0 then @nOre_luna_tura when @nButon_calcul=4 and max(p.tip_salarizare) in ('1','2') then @nOre_luna/8 when @nButon_calcul=4 and max(p.tip_salarizare) not in ('1','2') then @Nrmediu_ore_luna/8 else @Ore_calcul_co/8 end) as zile_luna, sum(a.Indemnizatie_co_an) as Indemnizatie_co_an, sum(a.Zile_co_efectuat_an) as Zile_co_efectuat_an,
(case when @Ordonare_locm='2' then max(isnull(p.Loc_de_munca,b.Loc_de_munca)) else '' end) as ordonare
from dbo.fPSDate_istoric_co (@Datajos, @Datasus, @lLocm, @pLocm, @lStrict, @lMarca, @pMarca, @lCod_functie, @pCod_functie, @lLocm_statie, @pLocm_statie, @lGrupa_munca, @cGrupa_munca, @lGrupa_exceptata, @lTipstat, @pTipstat, @Istoric_co_pt_zile_co_ramase,  @Zile_ramase_fct_cuvenite_la_luna) a 
left outer join personal b on a.marca=b.marca
left outer join infopers d on a.marca=d.marca
left outer join istpers p on a.data=p.data and a.marca=p.marca 
left outer join lm c on c.cod = b.loc_de_munca 
where a.data between @Datajos and @Datasus and a.Zile_co<>0 
and (@lLocm_statie=0 or p.Loc_de_munca like rtrim(@pLocm_statie)+'%') 
group by a.Data, a.marca
order by ordonare,(case when @Alfabetic=1 then max(b.nume) else a.marca end)
return
end
