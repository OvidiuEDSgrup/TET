--***
/**	functie concedii de odihna	
	@dataJos -> prima zi din an
	@dataSus -> ultima zi din luna de lucru
*/
Create
function frapConcediiOdihnaPeAn
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, @grupamunca char(1)=null, @grupaexceptata int=0, 
	@tippersonal char(1)=null, @tipstat varchar(30)=null, @primavacantacorD int, @ordonare char(1), @alfabetic int=0, @tipzileramase int)
returns @concedii_odihna table
	(data datetime, marca char(6), nume char(50), lm char(9), den_lm char(30), grupa_de_munca char(1), vechime_totala datetime, 
	vechime_in_ani int, data_angajarii datetime, loc_ramas_vacant int, data_plecarii datetime, 
	zile_co_an int, zile_co_suplim_an int, zile_co_neefectuat_an_ant int, zile_co_efectuat_in_luna int, zile_co_efectuat_din_an_ant int, zile_co_efectuat_an int, 
	prima_de_concediu float, indemnizatie_co_an int, indemnizatie_co_luna_curenta float, co_incasat float, zile_co_cuvenite_an int, zile_co_cuvenite_la_luna int, 
	zile_co_cuvenite int, zile_co_ramase int, grupare char(50))
as
begin
	declare @Zile_co_ramase bit, @Dataj12_anant datetime, @Datas12_anant datetime, @Subtipcor int, @ZileCOVechUnit int, 
	@dreptConducere int, @areDreptCond int, @lista_drept char(1)

	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	Set @Dataj12_anant=dbo.bom(dateadd(day,-1,@dataJos))
	Set @Datas12_anant=dateadd(day,-1,@dataJos)
	Set @Zile_co_ramase=dbo.iauParL('PS','ZILECORAM')
	Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	Set @ZileCOVechUnit=dbo.iauParL('PS','ZICOVECHU')

	declare @utilizator varchar(20)
	SET @utilizator = dbo.fIaUtilizator('')

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept='T'
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end 

	insert into @concedii_odihna
	select @dataSus as data, p.marca, p.nume, p.loc_de_munca as lm, lm.denumire as den_lm, p.grupa_de_munca, p.vechime_totala, 
	(case when @ZileCOVechUnit=0 then left(dbo.fVechimeAALLZZ(p.vechime_totala),2) else convert(int,left(ip.Vechime_la_intrare,2)) end) as vechime_in_ani,
	p.data_angajarii_in_unitate as data_angajarii, convert(int,p.loc_ramas_vacant) as loc_ramas_vacant, p.data_plec as data_plecarii, 
	p.zile_concediu_de_odihna_an as zile_co_an, p.zile_concediu_efectuat_an as zile_co_suplim_an, isnull(ia.coef_invalid,0) as zile_co_neefectuat_an_ant, isnull(bl.Zile_co_efectuat_in_luna,0) as zile_co_efectuat_in_luna,
	isnull((select sum((case when c.tip_concediu='5' then -1 else 1 end)*c.zile_co) from concodih c where c.data between @dataJos and @dataSus and p.marca=c.marca 
		and (c.tip_concediu='4' or c.tip_concediu='6' or c.tip_concediu='8' or c.tip_concediu='5' and exists (select marca from concodih h where h.data=c.data and h.marca=c.marca 
		and h.tip_concediu in ('4','8') and c.data_inceput>=h.data_inceput and c.data_inceput<=h.data_sfarsit))),0) as zile_co_efectuat_din_an_ant,
	isnull(ba.Zile_co_efectuat_an,0) + isnull((select sum(c.zile_co) from concodih c where c.data between @dataJos and @dataSus and p.marca=c.marca and (c.tip_concediu='3' or c.tip_concediu='6')),0) as zile_co_efectuat_an, 
	isnull((select sum(e.suma_corectie) from corectii e where e.data between @dataJos and @dataSus and p.marca=e.marca 
		and (@primavacantacorD=1 and (@Subtipcor=0 and e.tip_corectie_venit='D-' 
		or @Subtipcor=1 and e.tip_corectie_venit in (select subtip from subtipcor where tip_corectie_venit='D-')) 
		or @primavacantacorD=0 and (@Subtipcor=0 and e.tip_corectie_venit='O-' 
		or @Subtipcor=1 and e.tip_corectie_venit in (select subtip from subtipcor where tip_corectie_venit='O-')))),0) as prima_de_concediu, 
	isnull(ba.Indemnizatie_CO_an,0) as indemnizatie_co_an,  isnull(bl.Indemnizatie_CO_luna,0) as indemnizatie_co_luna_curenta,
	(select sum(g.co_incasat) from net g where g.data between dbo.bom(@dataSus) and @dataSus and p.marca=g.marca) as co_incasat, 
	isnull(zcan.zile,0) as zile_co_cuvenite_an, isnull(zcl.zile,0) as zile_co_cuvenite_la_luna, 
	(case when @tipzileramase=1 then isnull(zcl.zile,0) else isnull(zcan.zile,0) end) as zile_co_cuvenite, 
	isnull(ia.coef_invalid,0)+(case when @tipzileramase=1 then isnull(zcl.zile,0) else isnull(zcan.zile,0) end)-zile_co_efectuat_an as zile_co_ramase,
	(case when @Ordonare='2' then p.loc_de_munca else '' end) as grupare
	from personal p
		left join dbo.ls_zile_CO_cuvenite(@marca,@dataSus,0) zcan on zcan.marca=p.marca
		left join dbo.ls_zile_CO_cuvenite(@marca,@dataSus,1) zcl on zcl.marca=p.marca
		left outer join lm on p.loc_de_munca=lm.cod 
		left outer join infopers ip on ip.marca=p.marca 
		left outer join istpers ia on ia.data=@Datas12_anant and ia.marca=p.marca and @Zile_co_ramase=1
		left outer join istpers i on i.data=@dataSus and i.marca=p.marca 
		left outer join (select Marca, sum(ore_concediu_de_odihna/(case when spor_cond_10=0 then 8 else spor_cond_10 end)) as Zile_co_efectuat_in_luna, 
			round(sum(ind_concediu_de_odihna),0) as Indemnizatie_CO_luna from brut where data between dbo.bom(@dataSus) and @dataSus Group by Marca) bl on bl.Marca=p.Marca
		left outer join (select Marca, sum(ore_concediu_de_odihna/(case when spor_cond_10=0 then 8 else spor_cond_10 end)) as Zile_co_efectuat_an, 
			round(sum(ind_concediu_de_odihna),0) as Indemnizatie_CO_an from brut where data between @dataJos and @dataSus Group by Marca) ba on ba.Marca=p.Marca
	where (@marca is null or p.marca=@marca) 
		and (@locm is null or p.loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@grupamunca is null or (@grupaexceptata=0 and p.grupa_de_munca=@grupamunca or @grupaexceptata=1 and p.grupa_de_munca<>@grupamunca)) 
		and (p.loc_ramas_vacant=0 and p.Data_angajarii_in_unitate<=dbo.EOM(@dataSus) 
			or p.Data_plec>=dbo.bom(@dataSus) or p.Data_angajarii_in_unitate>=dbo.BOM(@dataSus))
		and exists (select i.Marca from istpers i where data between @dataJos and @dataSus and Marca=p.marca) 
		and (@functie is null or p.Cod_functie=@functie) 
		and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7')))
		and (@tipstat is null or ip.religia=@tipstat)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 or @lista_drept='S' and p.pensie_suplimentara<>1)) 
		or (@dreptConducere=1 and @areDreptCond=0 and @lista_drept='S' and p.pensie_suplimentara<>1))
	order by Grupare, (case when @Alfabetic=1 then p.nume else p.marca end)
	return
end
