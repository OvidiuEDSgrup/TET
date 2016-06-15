--***
/**	functie pt. returnare date privind detasarea personalului */
Create function fAdevRevisalDetasari() 
returns @RevisalDetasari table 
	(NrCurent int identity(1,1), Marca char(6), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, 
	AngajatorCui varchar(20), AngajatorNume char(200), Nationalitate varchar(100), Nr_contract char(20), Data_contract datetime Unique (Marca, DataInceput))
As
Begin
	declare @HostID char(10), @Marca char(6), @dataJos datetime, @dataSus datetime, @RevisalSuspDinDL int, @utilizator varchar(50), @lista_lm int
	set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
--	Set @HostID='2336'
	set @Marca=isnull((select Numar from avnefac where AVNEFAC.TERMINAL=@HostID and tip='AD'),'')
	select @dataJos='01/01/1901'
	set @dataSus=dbo.eom(isnull((select Data from avnefac where AVNEFAC.TERMINAL=@HostID and tip='AD'),'01/01/1901'))

	set @utilizator=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert into @RevisalDetasari
--	selectez detasarile de contract din extinfop (datele introduse in macheta salariati - CTRL+J, Detasare salariati)
	select e.Marca, e.Data_inf, e1.Data_inf, e2.Data_inf, e.Val_inf, e1.Val_inf, e2.Val_inf, 
		i.Nr_contract, isnull((select max(data_inf) from extinfop e3 where e3.marca=e.marca and e3.cod_inf='DATAINCH'),'01/01/1901')
	from extinfop e 
		left outer join personal p on p.Marca=e.Marca
		left outer join infopers i on i.marca=e.marca
		left outer join lm l on l.Cod=p.Loc_de_munca
		left outer join extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='DETDATASF' and e.Procent=e1.Procent
		left outer join extinfop e2 on e2.Marca=e.Marca and e2.Cod_inf='DETNATIONAL' and e.Procent=e2.Procent
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where e.Cod_inf='DETDATAINC' and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
		and (@lista_lm=0 or lu.cod is not null)
	order by e.Data_inf

--	inlocuiesc caracterele speciale intrucat da eroare la deschidere document rezultat
	update @RevisalDetasari set Nationalitate=REPLACE(Nationalitate,'�','i')
	update @RevisalDetasari set Nationalitate=REPLACE(Nationalitate,'�','a')
	update @RevisalDetasari set Nationalitate=REPLACE(Nationalitate,'�','a')
	update @RevisalDetasari set Nationalitate=REPLACE(Nationalitate,'?','a')

	if not exists (select Marca from @RevisalDetasari) 
		insert into @RevisalDetasari
		select @Marca, '01/01/1901', '01/01/1901', '01/01/1901', '', '', '', '', '01/01/1901'
	
	return
End

/*
	select * from dbo.fAdevRevisalSuspendari() 
*/
