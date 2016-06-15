--***
/**	procedura generare concedii alte pe perioade ulterioare	*/
create procedure PSGenerareConAlte
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLocm char(9)
As
Begin try
	declare @dataSus_next datetime, @dataSus_next2 datetime, @dataSus_next3 datetime, @userASiS char(10), @Data_operarii datetime, @Ora_operarii char(6) 
	Set @dataSus_next=dbo.eom(dateadd(month,1,@dataSus))
	Set @dataSus_next2=dbo.eom(dateadd(month,2,@dataSus))
	Set @dataSus_next3=dbo.eom(dateadd(month,3,@dataSus))
	set @userASiS=dbo.fIaUtilizator(null)
	set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
	set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')

	delete from conalte where Data>@dataSus and Data=dbo.EOM(Data) and Introd_manual=1 and (@pMarca='' or marca=@pMarca) 
--	and Data_operarii in (select Data_operarii from conalte a where a.data=@dataSus and a.marca=conalte.marca and a.tip_concediu=conalte.tip_concediu)
		and exists (select 1 from conalte a where data=@dataSus and a.marca=conalte.marca and a.tip_concediu=conalte.tip_concediu and a.Data_sfarsit>@dataSus)
		and (@pLocm='' or Marca in (select Marca from personal where Loc_de_munca like rtrim(@pLocm)+'%'))

--	generez pozitiile pt. luna de lucru + 1
	insert into conalte
	(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie, Utilizator, Data_operarii, Ora_operarii)
	Select dbo.eom(dateadd(month,1,a.Data)), a.Marca, a.Tip_concediu, 
	dateadd(day,1,a.Data), 
	(case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec between dbo.bom(@dataSus_next) and @dataSus_next and p.Data_plec<a.Data_sfarsit then DateAdd(day,-1,p.Data_plec) 
		when a.Data_sfarsit>dbo.eom(dateadd(month,1,a.Data)) then dbo.eom(dateadd(month,1,a.Data)) else a.Data_sfarsit end), 
	dbo.zile_lucratoare(dateadd(day,1,a.Data), (case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec between dbo.bom(@dataSus_next) and @dataSus_next and p.Data_plec<a.Data_sfarsit 
		then DateAdd(day,-1,p.Data_plec) when a.Data_sfarsit>dbo.eom(dateadd(month,1,a.Data)) then dbo.eom(dateadd(month,1,a.Data)) else a.Data_sfarsit end)), 
	1, 0, @userASiS, @Data_operarii, @Ora_operarii
	from conalte a
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca) and a.tip_concediu in ('1','2','4','5','6','9','F','R') and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%') 
		and a.data_sfarsit>@dataSus 
		and not exists (select 1 from conalte b where b.data=dbo.eom(dateadd(month,1,a.Data)) and b.Marca=a.Marca and b.Data_inceput=dateadd(day,1,a.Data) and b.tip_concediu=a.Tip_concediu)

--	generez pozitiile pt. luna de lucru + 2
	insert into conalte
	(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie, Utilizator, Data_operarii, Ora_operarii)
	Select dbo.eom(dateadd(month,2,a.Data)), a.Marca, a.Tip_concediu, 
	dbo.bom(dateadd(month,2,a.Data)), 
	(case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec between dbo.bom(@dataSus_next2) and @dataSus_next2 and p.Data_plec<a.Data_sfarsit then DateAdd(day,-1,p.Data_plec) 
		when a.Data_sfarsit>dbo.eom(dateadd(month,2,a.Data)) then dbo.eom(dateadd(month,2,a.Data)) else a.Data_sfarsit end), 
	dbo.zile_lucratoare(dbo.bom(dateadd(month,2,a.Data)), 
		(case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec between dbo.bom(@dataSus_next2) and @dataSus_next2 and p.Data_plec<a.Data_sfarsit then DateAdd(day,-1,p.Data_plec) 
			when a.Data_sfarsit>dbo.eom(dateadd(month,2,a.Data)) then dbo.eom(dateadd(month,2,a.Data)) else a.Data_sfarsit end)), 
	1, 0, @userASiS, @Data_operarii, @Ora_operarii
	from conalte a
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca) and a.tip_concediu in ('1','4','5','6','9','F','R') and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%') 
		and a.data_sfarsit>dbo.eom(dateadd(month,1,Data))
		and not exists (select 1 from conalte b where b.data=dbo.eom(dateadd(month,2,a.Data)) and b.Marca=a.Marca and b.Data_inceput=dbo.bom(dateadd(month,2,a.Data)) 
			and b.tip_concediu=a.Tip_concediu)

--	generez pozitiile pt. luna de lucru + 3 (la Grup Sapte a fost cazul)
	insert into conalte
	(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie, Utilizator, Data_operarii, Ora_operarii)
	Select dbo.eom(dateadd(month,3,a.Data)), a.Marca, a.Tip_concediu, 
	dbo.bom(dateadd(month,3,a.Data)), 
	(case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec between dbo.bom(@dataSus_next3) and @dataSus_next3 and p.Data_plec<a.Data_sfarsit then DateAdd(day,-1,p.Data_plec) 
		else a.Data_sfarsit end), 
	dbo.zile_lucratoare(dbo.bom(dateadd(month,3,a.Data)), 
		(case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec between dbo.bom(@dataSus_next3) and @dataSus_next3 and p.Data_plec<a.Data_sfarsit then DateAdd(day,-1,p.Data_plec) 
			else a.Data_sfarsit end)), 
	1, 0, @userASiS, @Data_operarii, @Ora_operarii
	from conalte a
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca) and a.tip_concediu in ('1','4','5','6','9','F','R') and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%') 
		and a.data_sfarsit>dbo.eom(dateadd(month,2,Data)) 
		and not exists (select 1 from conalte b where b.data=dbo.eom(dateadd(month,3,a.Data)) and b.Marca=a.Marca and b.Data_inceput=dbo.bom(dateadd(month,3,a.Data)) 
			and b.tip_concediu=a.Tip_concediu)
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura PSGenerareConAlte (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
