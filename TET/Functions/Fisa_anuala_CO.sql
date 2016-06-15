--***
/**	functie Fisa anuala CO	*/
Create 
function  [dbo].[Fisa_anuala_CO] 
	(@dDatajos datetime, @dDatasus datetime, @lFiltru_marca int, @cMarca char(6), @FltLocm int, @cLocm char(9), @lStrict int, 
	@FltFunctie int, @cFunctie char(6), @lGrupa_munca int, @cGrupa_munca char(1), @lGrupa_exceptata int, @lAlfabetic int, @cOrdonare char(1))
returns @date_fisa_co table
	(Marca char(6), Nume char(50), Cod_functie char(6), Loc_de_munca char(9), Vechime_totala char(10), Data_angajarii_in_unitate datetime, ZileCo_an_ant float, Zile_CO_ev int, Zile_CO_an int, Denumire_functie char(30), Denumire_locm char(30), Zile_CO_luna1 int, Zile_CO_luna2 int, Zile_CO_luna3 int, Zile_CO_luna4 int, Zile_CO_luna5 int, Zile_CO_luna6 int, Zile_CO_luna7 int, Zile_CO_luna8 int, Zile_CO_luna9 int, Zile_CO_luna10 int, Zile_CO_luna11 int, Zile_CO_luna12 int, Total_zile_CO int, Ordonare char(30), Ordonare1 char(50))
as
begin
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)

	insert into @date_fisa_co
	select a.marca, max(b.nume), max(b.cod_functie), max(b.Loc_de_munca), convert(char(10),max(b.vechime_totala),111), 
		max(b.data_angajarii_in_unitate), max(isnull(e.coef_invalid,0)), sum(isnull(f.zile_co,0)), 
		max(b.Zile_concediu_de_odihna_an), max(c.denumire), max(d.denumire), 
		sum((case when month(a.data)=1 then a.Zile_CO else 0 end)+(case when month(g.data)=1 then g.zile_co else 0 end)),
		sum((case when month(a.data)=2 then a.Zile_CO else 0 end)+(case when month(g.data)=2 then g.zile_co else 0 end)),
		sum((case when month(a.data)=3 then a.Zile_CO else 0 end)+(case when month(g.data)=3 then g.zile_co else 0 end)),
		sum((case when month(a.data)=4 then a.Zile_CO else 0 end)+(case when month(g.data)=4 then g.zile_co else 0 end)),
		sum((case when month(a.data)=5 then a.Zile_CO else 0 end)+(case when month(g.data)=5 then g.zile_co else 0 end)),
		sum((case when month(a.data)=6 then a.Zile_CO else 0 end)+(case when month(g.data)=6 then g.zile_co else 0 end)),
		sum((case when month(a.data)=7 then a.Zile_CO else 0 end)+(case when month(g.data)=7 then g.zile_co else 0 end)),
		sum((case when month(a.data)=8 then a.Zile_CO else 0 end)+(case when month(g.data)=8 then g.zile_co else 0 end)),
		sum((case when month(a.data)=9 then a.Zile_CO else 0 end)+(case when month(g.data)=9 then g.zile_co else 0 end)),
		sum((case when month(a.data)=10 then a.Zile_CO else 0 end)+(case when month(g.data)=10 then g.zile_co else 0 end)),
		sum((case when month(a.data)=11 then a.Zile_CO else 0 end)+(case when month(g.data)=11 then g.zile_co else 0 end)),
		sum((case when month(a.data)=12 then a.Zile_CO else 0 end)+(case when month(g.data)=12 then g.zile_co else 0 end)), 0,
		(case when @cOrdonare='2' then max(b.loc_de_munca) else '' end) as Ordonare, 
		(case when @lAlfabetic=1 then max(b.nume) else a.marca end) as Ordonare1 
	from (select data, marca, sum(Ore_concediu_de_odihna/(case when Spor_cond_10=0 then 8 else Spor_cond_10 end)) as Zile_CO
	from brut where data between @dDatajos and @dDatasus group by data, marca) a 
		left outer join personal b on a.marca=b.marca 
		left outer join functii c on b.cod_functie=c.cod_functie
		left outer join lm d on b.loc_de_munca=d.cod
		left outer join istpers e on e.marca=a.marca and e.data between dateadd(month,-1,@dDatajos) and dateadd(day,-1,@dDatajos)
		left outer join (select Data, Marca, sum(Zile_CO) as Zile_CO from concodih where data between @dDatajos and @dDatasus 
		and tip_concediu='2' group by Data, Marca) f on f.marca=a.marca and f.data=a.data
		left outer join (select Data, Marca, sum(Zile_CO) as Zile_CO from concodih where data between @dDatajos and @dDatasus 
		and tip_concediu in ('3','6') group by Data, Marca) g on g.marca=a.marca and g.data=a.data
	where a.data between @dDatajos and @dDatasus and (@lFiltru_marca=0 or a.marca=@cMarca ) 
		and (@FltLocm=0 or @lStrict=1 and b.Loc_de_munca=@cLocm or b.Loc_de_munca like rtrim(@cLocm)+'%') 
		and (@lGrupa_munca=0 or (@lGrupa_exceptata=0 and b.Grupa_de_munca=@cGrupa_munca or @lGrupa_exceptata=1 
		and b.Grupa_de_munca<>@cGrupa_munca)) and (@FltFunctie=0 or b.Cod_functie=@cFunctie)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=b.Loc_de_munca))
	group by a.marca
	order by Ordonare, Ordonare1

	update @date_fisa_co
		Set Total_zile_co=Zile_CO_luna1+Zile_CO_luna2+Zile_CO_luna3+Zile_CO_luna4+Zile_CO_luna5+Zile_CO_luna6+Zile_CO_luna7 +Zile_CO_luna8+Zile_CO_luna9+Zile_CO_luna10+Zile_CO_luna11+Zile_CO_luna12+Zile_CO_ev
	return
end
