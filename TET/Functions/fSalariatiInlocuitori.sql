--***
/**	functie pt. returnare date privind salariatii inlocuitori */
Create function fSalariatiInlocuitori
	(@dataJos datetime, @dataSus datetime, @marca char(6)) 
returns @SalariatiInlocuitori table 
	(Data datetime, Marca char(6), Marca_inlocuitoare char(6), Data_inceput datetime, Data_sfarsit datetime, Motiv char(80) Unique (Data, Marca, Data_inceput))
As
Begin
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert into @SalariatiInlocuitori
--	selectez salariatii inlocuitori de contract din extinfop (datele introduse in macheta salariati)
	select @dataSus, e.Marca, e.Val_inf, e.Data_inf, e1.Data_inf, e1.Val_inf
	from Extinfop e 
		left outer join Extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='SALINLOCSF' and e.Procent=e1.Procent
		left outer join istPers i on i.Data=@dataSus and i.Marca=e.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.Loc_de_munca
	where e.Cod_inf='SALINLOCIN' and (@Marca='' or e.Marca=@Marca)
		and (@dataJos between e.Data_inf and e1.Data_inf or @dataSus between e.Data_inf and e1.Data_inf)
		and (@lista_lm=0 or lu.cod is not null)

	return
End

/*
	select * from dbo.fSalariatiInlocuitori ('01/01/2012', '03/31/2012', '') 
*/
