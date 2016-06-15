--***
/**	procedura pontaj pe marca,locm	*/
Create procedure dbo.pPontaj_marca_locm 
	@dataJos datetime, @dataSus datetime, @Marca char(6), @Loc_de_munca char(6)
As
Begin try
	declare @STOUG28 int, @IT1SuspContr int, @IT2SuspContr int, @IT3SuspContr int, @denIntrTehn3 varchar(30), @Colas int

	set @STOUG28=dbo.iauParLL(@dataSus,'PS','STOUG28')
	set @IT1SuspContr=dbo.iauParL('PS','IT1-SUSPC')
	set @IT2SuspContr=dbo.iauParL('PS','PROC2INT')
	set @IT3SuspContr=dbo.iauParL('PS','PROC3INT')
	set @denIntrTehn3=dbo.iauParA('PS','PROC3INT')
	set @Colas=dbo.iauParL('SP','COLAS')

	if object_id('tempdb..#pontaj_marca_locm') is not null 
		insert into #Pontaj_marca_locm
		select @dataSus, Marca, Loc_de_munca, max(regim_de_lucru) as regim_de_lucru, max(grupa_de_munca) as grupa_de_munca, max(tip_salarizare) as tip_salarizare, 
			max(coeficient_acord) as coeficient_acord, 
			sum((case when @IT1SuspContr=1 then Ore_intrerupere_tehnologica else 0 end)) as Ore_intr_tehn_1, 
			sum((case when @STOUG28=1 or @IT2SuspContr=1 then ore else 0 end)) as Ore_intr_tehn_2, 
			sum((case when @Colas=1 then spor_cond_8 else 0 end)) as Ore_intemperii, 
			sum((case when @denIntrTehn3<>'' and @IT3SuspContr=1 then Spor_cond_8 else 0 end)) as Ore_intr_tehn_3
		from pontaj
		where data between @dataJos and @dataSus and (@Marca='' or marca=@Marca) 
			and (@Loc_de_munca='' or loc_de_munca like rtrim(@Loc_de_munca)+'%' )
		group by marca, loc_de_munca
	else 
		select @dataSus, Marca, Loc_de_munca, max(regim_de_lucru) as regim_de_lucru, max(grupa_de_munca) as grupa_de_munca, max(tip_salarizare) as tip_salarizare, 
			max(coeficient_acord) as coeficient_acord, 
			sum((case when @IT1SuspContr=1 then Ore_intrerupere_tehnologica else 0 end)) as Ore_intr_tehn_1, 
			sum((case when @STOUG28=1 or @IT2SuspContr=1 then ore else 0 end)) as Ore_intr_tehn_2, 
			sum((case when @Colas=1 then spor_cond_8 else 0 end)) as Ore_intemperii, 
			sum((case when @denIntrTehn3<>'' and @IT3SuspContr=1 then Spor_cond_8 else 0 end)) as Ore_intr_tehn_3
		from pontaj
		where data between @dataJos and @dataSus and (@Marca='' or marca=@Marca) 
			and (@Loc_de_munca='' or loc_de_munca like rtrim(@Loc_de_munca)+'%' )
		group by marca, loc_de_munca			
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pPontaj_marca_locm (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

