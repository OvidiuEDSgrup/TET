--***
/**	procedura generare CO	*/
Create procedure  psGenerare_CO
	@dataJos datetime, @dataSus datetime, @marca varchar(6)=null, @lm varchar(9)=null
As
Begin
	declare @utilizator varchar(10), @dataSus_next datetime

	set @utilizator = dbo.fIaUtilizator(null)
	set @dataSus_next=dbo.eom(dateadd(month,1,@dataSus))

	if @marca is null set @marca=''
	if @lm is null set @lm=''

	delete co 
	from concodih co
		left outer join personal p on p.Marca=co.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
	where co.data>@dataSus and tip_concediu in ('7','8','2','E') and (@marca='' or co.marca=@marca) 
		and prima_vacanta in (select prima_vacanta from concodih a where a.data=@dataSus and a.marca=co.marca and a.tip_concediu in ('1','4','2','E'))
		and (@lm='' or co.Marca in (select Marca from personal where Loc_de_munca like rtrim(@lm)+'%'))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	insert into ConcOdih
		(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile_CO, Introd_manual, Indemnizatie_CO, Zile_prima_vacanta, Prima_vacanta)
	Select dbo.eom(dateadd(month,1,a.Data)), a.Marca, (case when a.Tip_concediu='1' then '7' when a.Tip_concediu='4' then '8' else a.Tip_concediu end), 
		dateadd(day,1,a.Data), (case when a.Data_sfarsit>dbo.eom(dateadd(month,1,a.Data)) then dbo.eom(dateadd(month,1,a.Data)) else a.Data_sfarsit end), 
		dbo.zile_lucratoare(dateadd(day,1,a.Data), (case when a.Data_sfarsit>dbo.eom(dateadd(month,1,a.Data)) then dbo.eom(dateadd(month,1,a.Data)) else a.Data_sfarsit end)), 0, 0, 0, a.Prima_vacanta
	from concodih a
		left outer join personal p on a.marca=p.marca 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
	where a.data between @dataJos and @dataSus and (@marca='' or a.marca=@marca) and a.tip_concediu in ('1','4','2','E') 
		and (@lm='' or p.Loc_de_munca like rtrim(@lm)+'%') and a.data_sfarsit>@dataSus
		and not exists (select 1 from concodih b where b.data=dbo.eom(dateadd(month,1,a.Data)) and b.Marca=a.Marca 
			and b.Data_inceput=dateadd(day,1,a.Data) and b.tip_concediu=(case when a.Tip_concediu='1' then '7' when a.Tip_concediu='4' then '8' else a.Tip_concediu end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	insert into ConcOdih
		(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile_CO, Introd_manual, Indemnizatie_CO, Zile_prima_vacanta, Prima_vacanta)
	Select dbo.eom(dateadd(month,2,a.Data)), a.Marca, (case when a.Tip_concediu='1' then '7' when a.Tip_concediu='4' then '8' else a.Tip_concediu end), 
		dbo.bom(dateadd(month,2,a.Data)), a.Data_sfarsit, 
		dbo.zile_lucratoare(dbo.bom(dateadd(month,2,a.Data)), a.Data_sfarsit), 0, 0, 0, a.Prima_vacanta
	from concodih a
		left outer join personal p on a.marca=p.marca 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
	where a.data between @dataJos and @dataSus and (@marca='' or a.marca=@marca) and a.tip_concediu in ('1','4','2','E') 
		and (@lm='' or p.Loc_de_munca like rtrim(@lm)+'%') and a.data_sfarsit>dbo.eom(dateadd(month,1,Data))
		and not exists (select 1 from concodih b where b.data=dbo.eom(dateadd(month,2,a.Data)) and b.Marca=a.Marca 
			and b.Data_inceput=dbo.bom(dateadd(month,2,a.Data)) and b.tip_concediu=(case when a.Tip_concediu='1' then '7' when a.Tip_concediu='4' then '8' else a.Tip_concediu end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
End
