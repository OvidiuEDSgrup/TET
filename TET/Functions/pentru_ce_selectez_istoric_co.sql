Create
function [dbo].[pentru_ce_selectez_istoric_co] (@Datajos datetime, @Datasus datetime, @lLocm int, @pLocm char(9), @lStrict int, 
@lMarca int, @pMarca char(6), @lCod_functie int, @pCod_functie char(6), @lLocm_statie int, @pLocm_statie char(9), 
@lGrupa_munca int, @cGrupa_munca char(1), @lGrupa_exceptata int, @lTipstat int, @pTipstat char(10), @Istoric_co_pt_zile_co_ramase int, @Zile_ramase_fct_cuvenite_la_luna int)
returns @date_pentru_istoric_co table
(Data datetime, Marca char(6), Zile_CO int, Indemnizatie_co float, Indemnizatie_co_an float, Zile_co_efectuat_an int)
as
begin
declare @Data1_an datetime
Set @Data1_an=dbo.boy(@Datasus)
if @Istoric_co_pt_zile_co_ramase=0 
Begin
insert into @date_pentru_istoric_co
select dbo.eom(a.Data), a.marca as marca, sum(a.ore_concediu_de_odihna/a.regim_de_lucru) as Zile_co,
isnull((select sum(r.ind_concediu_de_odihna) from brut r where r.data=@Datasus and r.marca = a.marca),0) as Indemnizatie_co, 
isnull((select sum(r.ind_concediu_de_odihna) from brut r where r.data between @Data1_an and @Datasus and r.marca = a.marca),0) as Indemnizatie_co_an, 0 as Zile_co_efectuat_an
from pontaj a 
left outer join personal b on a.marca=b.marca
left outer join infopers d on a.marca=d.marca
left outer join istpers p on a.data=p.data and a.marca=p.marca 
left outer join lm c on c.cod = b.loc_de_munca 
where @Istoric_co_pt_zile_co_ramase=0 and a.data between @Datajos and @Datasus and a.ore_concediu_de_odihna<>0
and (@lLocm=0 or p.Loc_de_munca like rtrim(@pLocm)+(case when @lStrict=0 then '%' else '' end)) 
and (@lMarca=0 or a.marca=@pMarca) and (@lCod_functie=0 or p.cod_functie = @pCod_functie)
and (@lLocm_statie=0 or p.Loc_de_munca like rtrim(@pLocm_statie)+'%') 
and (@lGrupa_munca=0 or (@lGrupa_exceptata=0 and b.grupa_de_munca=@cGrupa_munca or @lGrupa_exceptata=1 and b.grupa_de_munca<>@cGrupa_munca)) and (@lTipstat=0 or d.religia=@pTipstat)
group by dbo.eom(a.Data), a.marca
End
If @Istoric_co_pt_zile_co_ramase=1
Begin
insert into @date_pentru_istoric_co
select a.Data, a.Marca, sum(a.Zile_co_neefectuat_an_ant+(case when @Zile_ramase_fct_cuvenite_la_luna=1 then Zile_co_cuvenite_la_luna else a.Zile_co_cuvenite_an end)-a.Zile_co_efectuat_an), 0 as Indemnizatie_co,  
isnull((select sum(r.ind_concediu_de_odihna) from brut r where r.data between @Data1_an and @Datasus and r.marca = a.marca),0) as Indemnizatie_co_an, sum(Zile_co_efectuat_an) as Zile_co_efectuat_an
from dbo.concedii_de_odihna(@Data1_an, @Datasus, 0, @lMarca, @pMarca, @lLocm, @pLocm, @lStrict, @lCod_functie, @pCod_functie, @lGrupa_munca, @cGrupa_munca, @lGrupa_exceptata, @lTipstat, @pTipstat, '', 0) a
where a.Zile_co_neefectuat_an_ant+(case when @Zile_ramase_fct_cuvenite_la_luna=1 then Zile_co_cuvenite_la_luna else a.Zile_co_cuvenite_an end)-a.Zile_co_efectuat_an<>0
group by a.Data, a.marca
End
return
end
