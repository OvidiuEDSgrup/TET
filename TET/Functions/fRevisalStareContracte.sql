--***
/**	functie pt. returnare date privind starea contractelor pt. registru electronic */
Create function fRevisalStareContracte 
	(@dataJos datetime, @dataSus datetime, @Marca char(6), @DataRegistru datetime, @SiActiviIncetati int, @SiUltimaStareAnt int) 
returns @StareContracte table 
	(Data datetime, Marca char(6), StareContract char(50), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, TemeiLegal varchar(50), 
	AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate varchar(50) Unique (Data, Marca, StareContract, DataInceput))
As
Begin
	declare @utilizator varchar(20), @lista_lm int, @Bugetari int, @DataRegistruPlecati datetime
		,@RevisalSuspDinDL int --variabila pentru generare suspendari contracte (CFS, Ingrijire copil, poate si absente nemotivate) din datele lunare - conalte, conmed, etc.
		,@multiFirma int
	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @Bugetari=dbo.iauParL('PS','UNITBUGET')
	set @RevisalSuspDinDL=dbo.iauParL('PS','REVSUSPDL')
	
	set @DataRegistruPlecati=@DataRegistru
--	determin intr-o variabila data de filtrare pt. salariatii plecati
--	daca se genereaza fisierul la o data imediat anterioara unei de zile libere sau de sarbatoare legala, sa-i aduca si pe cei plecati in zilele de sambata/duminca sau sarbatoare legala
	if datename(WeekDay, DateAdd(day,1,@DataRegistru))='Saturday' or DateAdd(day,1,@DataRegistru) in (select data from calendar)
	Begin
		set @DataRegistruPlecati=DateAdd(day,1,@DataRegistru)
		while datename(WeekDay, @DataRegistruPlecati) in ('Saturday','Sunday') or @DataRegistruPlecati in (select data from calendar)
			Set @DataRegistruPlecati = dateadd(day, 1, @DataRegistruPlecati)
--	la final dau data in urma; am nevoie de ultima libera
		set @DataRegistruPlecati=DateAdd(day,-1,@DataRegistruPlecati)
	End
	
	insert into @StareContracte
--	selectez concediile fara salar \  incepand cu 15.12.2011 nemotivatele >=1 zi \ incepand cu 27.02.2011 cercetarea disciplinara introduse in macheta Concedii\alte 
--	(pe TemeiSuspendare=Art54, Art51Alin2, Art52Alin1LiteraA)
--	momentan asta functioneaza doar pt. GrupSapte. Cu timpul poate se va folosi si de altii.
	select a.Data, a.Marca, 'ContractStareSuspendare', 
	dbo.fDataInceputCA(a.Data, a.Marca, a.Data_inceput, a.Tip_concediu), 
	dbo.fDataSfarsitCA(a.Data, a.Marca, a.Data_sfarsit, a.Tip_concediu), 
	'01/01/1901' as Data_incetare, (case when a.Tip_concediu='1' then 'Art54' when a.Tip_concediu='2' then 'Art51Alin2' when a.Tip_concediu='9' then 'Art52Alin1LiteraA' end) as TemeiLegal, '', '', ''
	from conalte a
	where @RevisalSuspDinDL=1 and a.Data between @dataJos and @dataSus and (@Marca='' or a.Marca=@Marca) 
		and (a.Tip_concediu='1' or a.Tip_concediu='2' and a.Indemnizatie=0 or a.Tip_concediu='9')
		and @DataRegistru between dbo.fDataInceputCA(a.Data, a.Marca, a.Data_inceput, a.Tip_concediu) and dbo.fDataSfarsitCA(a.Data, a.Marca, a.Data_sfarsit, a.Tip_concediu)
	Group by a.Data, a.Marca, a.Tip_concediu, 
		dbo.fDataInceputCA(a.Data, a.Marca, a.Data_inceput, a.Tip_concediu), 
		dbo.fDataSfarsitCA(a.Data, a.Marca, a.Data_sfarsit, a.Tip_concediu)
--	selectez suspendarile de contract din extinfop (datele introduse in macheta salariati)
	union all
	select isnull(i.Data,@datasus), e.Marca, 'ContractStareSuspendare', e.Data_inf, e1.Data_inf, e2.Data_inf, e.Val_inf, '', '', ''
	from Extinfop e 
		left outer join Extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='SCDATASF' and e.Procent=e1.Procent
		left outer join Extinfop e2 on e2.Marca=e.Marca and e2.Cod_inf='SCDATAINCET' and e.Procent=e2.Procent
		left outer join istPers i on i.Marca=e.Marca and i.Data=@dataSus
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where e.Cod_inf='SCDATAINC' and (@Marca='' or e.Marca=@Marca)
		and (@DataRegistru between e.Data_inf and (case when isnull(e2.Data_inf,'01/01/1901')<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
--	daca o suspendare nu este incetata si se genereaza registru la o data > data sfarsit suspendare, suspendarea sa apara activa. Pt. moment doar la Angajatorul.
			or @multiFirma=1 and @DataRegistru>e1.Data_inf and isnull(e2.Data_inf,'01/01/1901')='01/01/1901')
--	o incetare deja incetata sa sa nu mai fie considerata activa indiferent de data la care se genereaza registru. Pt. moment tot doar la Angajatorul.
		and not(@multiFirma=1 and isnull(e2.Data_inf,'01/01/1901')<>'01/01/1901')
		and (@lista_lm=0 or lu.cod is not null) 
--	tratat sa nu se ia in calcul supendarea prin detasare. Aceasta va fi inregistrata la detasari.
		and e.Val_inf<>'Art52Alin1LiteraD'
--	selectez detasarile de contract din Extinfop (datele introduse in macheta salariati)
	union all
	select isnull(i.Data,@datasus), e.Marca, 'ContractStareDetasare', e.Data_inf, e1.Data_inf, e2.Data_inf, '', e.Val_inf, e1.Val_inf, e2.Val_inf
	from Extinfop e 
		left outer join Extinfop e1 on e1.Marca=e.Marca and e1.Cod_inf='DETDATASF' and e.Procent=e1.Procent
		left outer join Extinfop e2 on e2.Marca=e.Marca and e2.Cod_inf='DETNATIONAL' and e.Procent=e2.Procent
		left outer join istPers i on i.Marca=e.Marca and i.Data=@dataSus
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where e.Cod_inf='DETDATAINC' and (@Marca='' or e.Marca=@Marca)
		and @DataRegistru between e.Data_inf and (case when isnull(e2.Data_inf,'01/01/1901')<>'01/01/1901' then DateAdd(day,-1,e2.Data_inf) else e1.Data_inf end)
		and (@lista_lm=0 or lu.cod is not null) 

--	completez aici ultima suspendare anterioara
	if @SiUltimaStareAnt=1
	begin
		declare @stari table (Marca varchar(6), StareContract varchar(100), Data_inceput datetime, Data_sfarsit datetime, Data_incetare datetime, Temei_legal varchar(100), 
			AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate varchar(50))
		insert into @stari
		select Marca, 'ContractStareSuspendare', Data_inceput, Data_sfarsit, Data_incetare, Temei_legal, '', '', ''
		from fRevisalSuspendari ('01/01/1901', @dataSus, @marca)
		union all 
		select Marca, 'ContractStareDetasare', DataInceput, DataSfarsit, DataIncetare, '', AngajatorCui, AngajatorNume, Nationalitate
		from fRevisalDetasari ('01/01/1901', @dataSus, @marca, @DataRegistru)
	
		insert into @StareContracte
		select @dataSus, Marca, StareContract, Data_inceput, Data_sfarsit, Data_incetare, Temei_legal, AngajatorCui, AngajatorNume, Nationalitate
		from (select Marca, StareContract, Data_inceput, Data_sfarsit, Data_incetare, Temei_legal, AngajatorCui, AngajatorNume, Nationalitate, 
			RANK() over (partition by Marca order by Data_inceput Desc) as ordine from @stari) a
		where ordine=1 and not exists (select 1 from @StareContracte sc where sc.Marca=a.Marca and sc.DataInceput=a.Data_inceput)
	end

	if @SiActiviIncetati=1 
		insert @StareContracte
		select i.Data, i.Marca, (case when convert(char(1),p.loc_ramas_vacant)='1' and p.Data_plec<>'01/01/1901' and p.Data_plec<=@DataRegistruPlecati 
			and (month(p.Data_plec)=month(i.Data) and year(p.Data_plec)=year(i.Data) or p.Data_plec between DateADD(day,1,i.Data) and @DataRegistruPlecati)
				then 'ContractStareIncetare' else 'ContractStareActiv' end) as StareCurenta, 
		p.Data_angajarii_in_unitate, (case when i.mod_angajare='D' then i.Data_plec else '01/01/1901' end), 
		(case when convert(char(1),p.loc_ramas_vacant)='1' and p.Data_plec<>'01/01/1901' and p.Data_plec<=@DataRegistruPlecati 
			and (month(p.Data_plec)=month(i.Data) and year(p.Data_plec)=year(i.Data) or p.Data_plec between DateADD(day,1,i.Data) and @DataRegistruPlecati)
				then p.Data_plec else '01/01/1901' end) as DataIncetareContract, 
		isnull((select max(rtrim(val_inf)) from Extinfop e where e.marca=i.marca and e.cod_inf='RTEMEIINCET'),''), '', '', ''
		from istPers i 
			left outer join personal p on p.Marca=i.Marca
			left outer join infoPers c on c.Marca=i.Marca			
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
			left outer join Extinfop e on e.Marca=i.Marca and e.Cod_inf='DATAINCH' and e.Data_inf<>'01/01/1901'
		where (i.data=@dataSus or i.Data=dbo.eom(DateAdd(day,1,@dataSus)) and p.Data_angajarii_in_unitate>@dataSus
				or convert(char(1),p.loc_ramas_vacant)='1' and i.Data<@dataJos and (i.Data>'08/01/2011' or @multiFirma=1 and e.Data_inf>='01/01/2013') 
					and MONTH(i.Data)=MONTH(p.Data_plec) and year(i.Data)=year(p.Data_plec))
			and (@Marca='' or i.Marca=@Marca) and i.Grupa_de_munca not in ('O','P','') and (@Bugetari=0 or convert(int,c.Actionar)=0) 
			and not exists (Select Marca from @StareContracte where Marca=i.Marca) 
			and (@lista_lm=0 or lu.cod is not null) 

	return
End

/*
	select * from dbo.fRevisalStareContracte ('12/01/2011', '12/31/2011', '81142 ', '12/31/2011', 1) --where marca in ('82545')
	select Marca from dbo.fRevisalStareContracte ('12/01/2011', '12/31/2011', '', '12/31/2011', 1) group by marca having count(1)>1
*/
