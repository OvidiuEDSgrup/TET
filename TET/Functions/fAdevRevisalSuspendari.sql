--***
/**	functie pt. returnare date privind suspendarea contractelor */
Create function fAdevRevisalSuspendari() 
returns @RevisalSuspendari table 
	(NrCurent int identity(1,1), Marca char(6), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, 
	TemeiLegal varchar(50), DescriereTemeiLegal char(100), Nr_contract char(20), Data_contract datetime 
	Unique (Marca, DataInceput))
As
Begin
	declare @HostID char(10), @Marca char(6), @DataJ datetime, @DataS datetime, @RevisalSuspDinDL int, @utilizator varchar(50), @lista_lm int
--	variabila @RevisalSuspDinDL - pentru generare suspendari contracte (CFS, Ingrijire copil, poate si absente nemotivate) 
--	din datele lunare - conalte, conmed, etc.
	set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
--	Set @HostID='2336'
	set @Marca=isnull((select Numar from avnefac where AVNEFAC.TERMINAL=@HostID and tip='AD'),'')
	select @DataJ='01/01/1901'
	set @DataS=dbo.eom(isnull((select Data from avnefac where AVNEFAC.TERMINAL=@HostID and tip='AD'),'01/01/1901'))
	set @RevisalSuspDinDL=dbo.iauParL('PS','REVSUSPDL')

	set @utilizator=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert into @RevisalSuspendari
--	selectez concediile fara salar si incepand cu 15.12.2011 si nemotivatele >=1 zi introduse in macheta Concedii\alte 
--	(pe TemeiSuspendare=Art54, respectiv Art51Alin2)
--	momentan asta functioneaza doar pt. GrupSapte. Cu timpul poate se va folosi si de altii.
	select a.Marca, 
	dbo.fDataInceputCA(a.Data, a.Marca, a.Data_inceput, a.Tip_concediu), 
	dbo.fDataSfarsitCA(a.Data, a.Marca, a.Data_sfarsit, a.Tip_concediu), 
	dbo.fDataSfarsitCA(a.Data, a.Marca, a.Data_sfarsit, a.Tip_concediu) as Data_incetare, 
	(case when a.Tip_concediu='1' then 'Art54' when a.Tip_concediu='2' then 'Art51Alin2' end) as TemeiLegal,
	left(max(c.Descriere),100), 
	max(i.Nr_contract), isnull((select max(data_inf) from extinfop e where e.marca=a.marca and e.cod_inf='DATAINCH'),'01/01/1901')
	from conalte a
 		left outer join infopers i on i.marca=a.marca
		left outer join CatalogRevisal c on c.TipCatalog='TemeiSuspendare' and c.Cod=(case when a.Tip_concediu='1' then 'Art54' when a.Tip_concediu='2' then 'Art51Alin2' end)
	where @RevisalSuspDinDL=1 and a.Data between @DataJ and @DataS and (@Marca='' or a.Marca=@Marca) 
		and (a.Tip_concediu='1' or a.Tip_concediu='2' and a.Indemnizatie=0)
	Group by a.Marca, a.Tip_concediu, 
	dbo.fDataInceputCA(a.Data, a.Marca, a.Data_inceput, a.Tip_concediu), 
	dbo.fDataSfarsitCA(a.Data, a.Marca, a.Data_sfarsit, a.Tip_concediu)
--	selectez suspendarile de contract din extinfop (datele introduse in macheta salariati - CTRL+J)
	union all
	select e.Marca, e.Data_inf, e1.Data_inf, e2.Data_inf, e.Val_inf, LEFT(c.Descriere,100),
	i.Nr_contract, isnull((select max(data_inf) from extinfop e3 where e3.marca=e.marca and e3.cod_inf='DATAINCH'),'01/01/1901')
	from Extinfop e 
		left outer join personal p on p.marca=e.marca
 		left outer join infopers i on i.marca=e.marca
		left outer join Extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='SCDATASF' and e.Procent=e1.Procent
		left outer join Extinfop e2 on e2.Marca=e.Marca and e2.Cod_inf='SCDATAINCET' and e.Procent=e2.Procent
		left outer join CatalogRevisal c on c.TipCatalog='TemeiSuspendare' and c.Cod=e.Val_inf
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where e.Cod_inf='SCDATAINC' and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
		and (@lista_lm=0 or lu.cod is not null)
--	tratat sa nu se ia in calcul supendarea prin detasare. Aceasta va fi inregistrata la detasari.
		and e.Val_inf<>'Art52Alin1LiteraD'

--	inlocuiesc caracterele speciale intrucat da eroare la deschidere document rezultat
	update @RevisalSuspendari set DescriereTemeiLegal=REPLACE(DescriereTemeiLegal,'�','i')
	update @RevisalSuspendari set DescriereTemeiLegal=REPLACE(DescriereTemeiLegal,'�','a')
	update @RevisalSuspendari set DescriereTemeiLegal=REPLACE(DescriereTemeiLegal,'�','a')
	update @RevisalSuspendari set DescriereTemeiLegal=REPLACE(DescriereTemeiLegal,'?','a')

	if not exists (select Marca from @RevisalSuspendari) 
		insert into @RevisalSuspendari
		select @Marca, '01/01/1901', '01/01/1901', '01/01/1901', '', '', '', '01/01/1901'
	
	return
End

/*
	select * from dbo.fAdevRevisalSuspendari() 
*/
