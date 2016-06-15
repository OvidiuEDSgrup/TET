--***
/*	procedura pentru centralizator certificate CM */
Create procedure rapCertificateCMFnuass (@datajos datetime, @datasus datetime, @alfabetic int) 
as
begin
	declare @utilizator varchar(20), @multiFirma int
	Set @utilizator = dbo.fIaUtilizator('')
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	select ROW_NUMBER() over (order by d.data, (case when @alfabetic=1 then a.numeAsig else d.cnpAsig end)) as numar_curent, 
		d.data, rtrim(a.numeAsig)+' '+rtrim(a.prenAsig) as nume, d.cnpasig, isnull(d.D_8,'') as cnp_copil, d.D_1 as serie_cm, d.D_2 as numar_cm, 
		isnull(d.D_3,'') as serie_cm_initial, isnull(d.D_4,'') as numar_cm_initial, d.D_9 as cod_indemnizatie, 
		(case when @alfabetic=1 then a.numeAsig else d.cnpAsig end) as ordonare
	from D112asiguratD d 
		left outer join D112asigurat a on a.Data=d.Data and a.cnpAsig=d.cnpAsig and (d.Loc_de_munca is null or a.Loc_de_munca=d.Loc_de_munca)
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=d.Loc_de_munca
	where d.data between @datajos and @datasus 
		and (@multiFirma=0 or lu.cod is not null)
	order by d.data, ordonare
	return
end

/*
	exec rapCertificateCMFnuass '05/01/2012', '05/31/2012', 0
*/
