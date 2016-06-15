--***
/**	procedura ce returneaza date pt. declaratia 205 */
Create function fSalariatiCuImpozitIpotetic
	(@dataJos datetime, @dataSus datetime, @lm char(9), @marca varchar(6)=null)
returns @ImpozitIpotetic table (data datetime, marca varchar(20), impozitIpotetic varchar(20))
Begin 
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert into @ImpozitIpotetic
	select @dataSus, Marca, ImpozitIpotetic 
	from 
	(select e.Marca, e.Val_inf as ImpozitIpotetic, RANK() over (partition by e.Marca order by e.Data_inf Desc) as ordine
		from extinfop e 
			left outer join istpers i on i.Data=@dataSus and i.Marca=e.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
		where cod_inf='IMPOZIPOTETIC' and Val_inf<>'' and Data_inf<=@dataSus
			and (isnull(@marca,'')='' or e.Marca=@marca) 
			and (isnull(@lm,'')='' or i.Loc_de_munca like rtrim(@lm)+'%') 
			and (@lista_lm=0 or lu.cod is not null)) a
	where Ordine=1
	return
End

/*
	select * from fSalariatiCuImpozitIpotetic ('01/01/2014', '01/31/2014', null, null)
*/
