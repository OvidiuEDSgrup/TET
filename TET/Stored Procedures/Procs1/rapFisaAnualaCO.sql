/**	procedura Fisa anuala CO	*/
Create procedure rapFisaAnualaCO 
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, 
	@grupa_munca char(1)=null, @grupa_exceptata int=0, @tippersonal char(1)=null, @alfabetic int, @ordonare char(1))
as
begin try
	declare @utilizator varchar(20),  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
		@ZileCOVechUnit int
	set @utilizator = dbo.fIaUtilizator(null)
	set @ZileCOVechUnit=dbo.iauParL('PS','ZICOVECHU')

	create table #fisa_co 
	(marca char(6), nume char(50), cod_functie char(6), den_functie char(30), lm char(9), den_lm char(30), vechime_totala char(8), data_angajarii datetime, 
	zile_co_an_ant float, zile_co_ev int, zile_co_an int, zile_co_supl int, zile_co_luna1 int, zile_co_luna2 int, zile_co_luna3 int, Zile_CO_luna4 int, zile_co_luna5 int, zile_co_luna6 int, 
	zile_co_luna7 int, zile_co_luna8 int, zile_co_luna9 int, zile_co_luna10 int, zile_co_luna11 int, zile_co_luna12 int, total_zile_co int, ordonare char(30), ordonare1 char(50))

	insert into #fisa_co
	select a.marca, max(p.nume), max(p.cod_functie), max(f.denumire), max(p.Loc_de_munca), max(lm.denumire), 
		max((case when @ZileCOVechUnit=0 then dbo.fVechimeAALLZZ(p.vechime_totala) else ip.Vechime_la_intrare end)) as vechime_totala, 
		max(p.data_angajarii_in_unitate), max(isnull(i.coef_invalid,0)), sum(isnull(co.zile_co_eveniment,0)), 
		max(p.Zile_concediu_de_odihna_an), max(p.Zile_concediu_efectuat_an) as zile_co_supl, 
		sum((case when month(a.data)=1 then a.Zile_CO else 0 end)+(case when month(co.data)=1 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=2 then a.Zile_CO else 0 end)+(case when month(co.data)=2 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=3 then a.Zile_CO else 0 end)+(case when month(co.data)=3 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=4 then a.Zile_CO else 0 end)+(case when month(co.data)=4 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=5 then a.Zile_CO else 0 end)+(case when month(co.data)=5 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=6 then a.Zile_CO else 0 end)+(case when month(co.data)=6 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=7 then a.Zile_CO else 0 end)+(case when month(co.data)=7 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=8 then a.Zile_CO else 0 end)+(case when month(co.data)=8 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=9 then a.Zile_CO else 0 end)+(case when month(co.data)=9 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=10 then a.Zile_CO else 0 end)+(case when month(co.data)=10 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=11 then a.Zile_CO else 0 end)+(case when month(co.data)=11 then co.zile_co_neefectuat else 0 end)),
		sum((case when month(a.data)=12 then a.Zile_CO else 0 end)+(case when month(co.data)=12 then co.zile_co_neefectuat else 0 end)), 0,
		(case when @ordonare='2' then max(p.loc_de_munca) else '' end) as Ordonare, 
		(case when @alfabetic=1 then max(p.nume) else a.marca end) as Ordonare1
	from (select data, marca, sum(Ore_concediu_de_odihna/(case when Spor_cond_10=0 then 8 else Spor_cond_10 end)) as Zile_CO 
				from brut where data between @dataJos and @dataSus group by data, marca) a 
		left outer join personal p on a.marca=p.marca 
		left outer join infoPers ip on a.marca=ip.marca 
		left outer join functii f on p.cod_functie=f.cod_functie
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join istpers i on i.marca=a.marca and i.data between dateadd(month,-1,@dataJos) and dateadd(day,-1,@dataJos)
		left outer join (select Data, Marca, sum((case when Tip_concediu in ('2','E') then Zile_CO else 0 end)) as zile_co_eveniment,
			sum((case when Tip_concediu in ('3','6') then Zile_CO else 0 end)) as zile_co_neefectuat
			from concodih where data between @dataJos and @dataSus 
			and tip_concediu in ('2','E','3','6') group by Data, Marca) co on co.marca=a.marca and co.data=a.data
	where a.data between @dataJos and @dataSus and (@marca is null or a.marca=@marca) 
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@grupa_munca is null or (@grupa_exceptata=0 and p.Grupa_de_munca=@grupa_munca or @grupa_exceptata=1 and p.Grupa_de_munca<>@grupa_munca)) 
		and (@functie is null or p.Cod_functie=@functie)
		and (@tippersonal is null or (@tippersonal='T' and i.tip_salarizare in ('1','2')) or (@tipPersonal='M' and i.tip_salarizare in ('3','4','5','6','7')))		
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
	group by a.marca
	order by Ordonare, Ordonare1

	update #fisa_co
		Set total_zile_co=zile_co_luna1+zile_co_luna2+zile_co_luna3+zile_co_luna4+zile_co_luna5+zile_co_luna6+zile_co_luna7 
			+zile_co_luna8+zile_co_luna9+zile_co_luna10+zile_co_luna11+zile_co_luna12+zile_co_ev
	
	select marca, nume, cod_functie, den_functie, lm, den_lm, vechime_totala, data_angajarii, 
		zile_co_an_ant, zile_co_ev, zile_co_an, zile_co_supl, zile_co_luna1, zile_co_luna2, zile_co_luna3, zile_CO_luna4, zile_co_luna5, zile_co_luna6, zile_co_luna7, 
		zile_co_luna8, zile_co_luna9, zile_co_luna10, zile_co_luna11, zile_co_luna12, total_zile_co, ordonare, ordonare1
	from #fisa_co
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapFisaAnualaCO (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
/*
	exec rapFisaAnualaCO '01/01/2012', '03/31/2012', '760', null, 0, null, null, 0, null, 0, '1'
*/
