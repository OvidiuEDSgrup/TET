--***
/**	functie pt. returnare date privind detasarile */
Create function fRevisalDetasari 
	(@dataJos datetime, @dataSus datetime, @Marca char(6), @DataRegistru datetime) 
returns 
	@Detasari table (Data datetime, Marca char(6), AngajatorCui varchar(20), AngajatorNume char(200), Nationalitate varchar(100), 
		DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, DataFinal datetime)
as
begin
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert @Detasari
	select @dataSus, e.Marca, e.Val_inf, e1.Val_inf, e2.Val_inf, e.Data_inf, e1.Data_inf, e2.Data_inf, 
		(case when isnull(e2.Data_inf,'')<='01/01/1901' then e1.Data_inf else e2.Data_inf end) as DataFinal
	from extinfop e 
		left outer join extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='DETDATASF' and e.Procent=e1.Procent
		left outer join extinfop e2 on e2.Marca=e.Marca and e2.Cod_inf='DETNATIONAL' and e.Procent=e2.Procent
		left outer join istPers i on i.Data=@dataSus and i.Marca=e.Marca
		left outer join personal p on p.Marca=e.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.Loc_de_munca)
	where e.Cod_inf='DETDATAINC' and (@Marca='' or e.Marca=@Marca) 
		and (@DataRegistru between e.Data_inf and (case when e2.Data_inf<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
			or @DataRegistru is null 
				and (@dataJos between e.Data_inf and (case when e2.Data_inf<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
					or @dataSus between e.Data_inf and (case when e2.Data_inf<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
					or e.Data_inf between @datajos and @datasus))
		and (@lista_lm=0 or lu.cod is not null) 

	return
end

/*
	select * from dbo.fRevisalDetasari('03/01/2011', '03/31/2011', '', '01/31/2014') 
*/
