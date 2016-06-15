--***
Create procedure rapListaVechimeSalariatiLaData 
	(@data datetime, @marca varchar(6)=null, @locm varchar(9)=null, @strict int=0, @functie varchar(6)=null, @tippersonal char(1)=null, 
	@tipstat varchar(30)=null, @grupare int, @alfabetic int, @vechanJos int=null, @vechanSus int=null)
as
/*
	Exemplu de apel
	exec rapListaVechimeSalariatiLaData @data='05/01/2015', @marca='T014', @locm=null, @strict=0, @functie=null, @tippersonal=null, @tipstat=null, @grupare='1', @alfabetic=1
*/
begin try
	set transaction isolation level read uncommitted

	declare @dataJos datetime, @dataSus datetime, @dreptConducere int, @areDreptCond int, @lista_drept char(1), @sub varchar(9), @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @sub=dbo.iauParA('GE','SUBPRO')
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')	
	SET @utilizator = dbo.fIaUtilizator(null) 
	select @dataJos=dbo.BOM(@data), @dataSus=dbo.EOM(@data)
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept='T'
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end 

	select data, marca, Vechime_totala_car, Vechime_la_intrare 
	into #vechimi
	from fCalculVechimeSporuri (@dataJos, @data, @Marca, 0, 0, '1', '', 1)

	select p.marca, p.nume, p.loc_de_munca as lm, lm.denumire as den_lm, p.cod_functie as functie, f.denumire as den_functie, 
		p.data_angajarii_in_unitate, (case when p.Loc_ramas_vacant=1 then convert(char(10),p.data_plec,103) else '' end) as data_plec, 
		v.Vechime_totala_car as vechime_totala, 
		left(v.Vechime_la_intrare,2)+'/'+substring(v.Vechime_la_intrare,3,2)+'/'+substring(v.Vechime_la_intrare,5,2) as Vechime_la_intrare, 
		(case when @grupare=2 then p.loc_de_munca else '' end) as grupare
	from personal p
		left outer join infopers ip on p.marca=ip.marca 
		left outer join istPers i on p.marca=i.marca and i.Data=@dataSus
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join functii f on p.cod_functie=f.cod_functie
		left outer join #vechimi v on v.marca=p.marca
	where (@marca is null or p.Marca=@marca) 
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (@functie is null or p.cod_functie=@functie) 
		and (@tipstat is null or ip.religia=@tipstat) 
		and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7')))
		and (p.marca in (select i.marca from istpers i where i.data=@dataSus) 
			or p.data_angajarii_in_unitate<=@dataSus and (convert(char(1),p.loc_ramas_vacant)='0' or (convert(char(1),p.loc_ramas_vacant)='1' and p.Data_plec>@dataJos))) 
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 or @lista_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @lista_drept='S' and p.pensie_suplimentara<>1))
		and (@vechanJos is null or convert(int,left(v.Vechime_totala_car,2)) between @vechanJos and @vechanSus
				or convert(int,left(v.Vechime_la_intrare,2)) between @vechanJos and @vechanSus)
	order by grupare, (case when @alfabetic=1 then p.nume else p.marca end)
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapListaVechimeSalariatiLaData (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
	
