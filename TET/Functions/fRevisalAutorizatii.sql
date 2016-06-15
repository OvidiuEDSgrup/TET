--***
/**	functie pt. returnare date privind autorizatiile pt. cetatenii NonUE */
Create function fRevisalAutorizatii 
	(@dataJos datetime, @dataSus datetime, @Marca char(6)) 
returns @Autorizatii table 
	(Marca char(6), TipAutorizatie char(50), DataInceput datetime, DataSfarsit datetime, nume varchar(50), lm varchar(9), denumire_lm varchar(30))
as
begin
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert @Autorizatii
	select e.Marca, e.Val_inf, e.Data_inf, e1.Data_inf, p.nume, isnull(i.Loc_de_munca,p.Loc_de_munca) as lm, lm.Denumire as denumire_lm
	from extinfop e 
		left outer join personal p on p.Marca=e.Marca
		left outer join extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='AUTDATASF' and e.Procent=e1.Procent
		left outer join istPers i on i.Data=@dataSus and i.Marca=e.Marca
		left outer join lm on lm.Cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where e.Cod_inf='AUTDATAINC' and (@Marca='' or e.Marca=@Marca)
		and (@dataJos between e.Data_inf and e1.Data_inf or @dataSus between e.Data_inf and e1.Data_inf 
			or p.Loc_ramas_vacant=1 and p.data_plec between e.Data_inf and e1.Data_inf)
		and (@lista_lm=0 or lu.cod is not null)

	return
end

/*
	select * from dbo.fRevisalAutorizatii('03/01/2011', '03/31/2011', '') 
*/
