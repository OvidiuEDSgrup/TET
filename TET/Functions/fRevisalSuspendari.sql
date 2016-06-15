--***
/**	functie pt. returnare date privind suspendarile de contractelor */
Create function fRevisalSuspendari
	(@dataJos datetime, @dataSus datetime, @marca char(6)) 
returns @SuspendariContracte table 
	(Data datetime, Marca char(6), Data_inceput datetime, Data_sfarsit datetime, Data_incetare datetime, Temei_legal varchar(50), Den_temei_legal varchar(300), nume varchar(50),
	lm varchar(9), denumire_lm varchar(30), cod_functie varchar(6), denumire_functie varchar(30), Data_final datetime	
	Unique (Data, Marca, Data_inceput))
--	returnez in data_final data de final a suspendarii in raport de data sfarsit / data incetarii (pentru a nu tot face case-uri in procedurile apelante)
As
Begin
	declare @utilizator varchar(20), @lista_lm int, @multiFirma int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	insert into @SuspendariContracte
--	selectez suspendarile de contract din extinfop (datele introduse in macheta salariati)
	select @dataSus, e.Marca, e.Data_inf, e1.Data_inf, e2.Data_inf, e.Val_inf, cs.Descriere as Den_temei_legal, p.Nume, 
		isnull(i.Loc_de_munca,p.Loc_de_munca) as lm, lm.Denumire as denumire_lm, isnull(i.Cod_functie,p.Cod_functie) as cod_functie, f.Denumire as denumire_functie, 
		(case when isnull(e2.Data_inf,'')<='01/01/1901' then e1.Data_inf else DateADD(day,-1,e2.Data_inf) end) as data_final
	from Extinfop e 
		left outer join Extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='SCDATASF' and e.Procent=e1.Procent
		left outer join Extinfop e2 on e2.Marca=e.Marca and e2.Cod_inf='SCDATAINCET' and e.Procent=e2.Procent
		left outer join personal p on p.Marca=e.Marca
		left outer join istPers i on i.Data=@dataSus and i.Marca=e.Marca
		left outer join CatalogRevisal cs on cs.TipCatalog='TemeiSuspendare' and e.Val_inf=cs.Cod
		left outer join lm on lm.Cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
		left outer join functii f on f.Cod_functie=isnull(i.Cod_functie,p.Cod_functie)
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where e.Cod_inf='SCDATAINC' and (@Marca='' or e.Marca=@Marca)
		and (@dataJos between e.Data_inf and (case when e2.Data_inf<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
			or @dataSus between e.Data_inf and (case when e2.Data_inf<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
			or e.Data_inf between @datajos and @datasus 
--	in cazul Angajator, dar poate fi caz general, cat timp o suspendare nu este incetata, salariatul este declarat Suspendat.
			or @multiFirma=1 and @dataSus>e1.Data_inf and isnull(e2.Data_inf,'01/01/1901')='01/01/1901')
		and (@lista_lm=0 or lu.cod is not null)
--	tratat sa nu se ia in calcul supendarea prin detasare. Aceasta va fi preluata ca detasare (din ce am inteles suspendarea prin detasare rezulta automat in Revisal pornind de la detasare).
--	totusi in cazul suspendarilor pe perioada detasarii, salariatul trebuie sa apara si ca suspendat.
		and (1=1 or e.Val_inf<>'Art52Alin1LiteraD')

	return
End

/*
	select * from dbo.fRevisalSuspendari ('01/01/2012', '03/31/2012', '') 
*/
