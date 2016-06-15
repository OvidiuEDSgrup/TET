--***
/**	procedura pt. registru electronic de salariati - date contracte */
Create procedure genRevisalContracte 
	(@dataJos datetime, @dataSus datetime, @DataRegistru datetime, @oMarca int=0, @cMarca char(6)='', @unLm int=0, @Lm char(9)='', @Strict int=0, @SirMarci varchar(1000)='', 
	@Judet varchar(15)='', @fltDataAngPl int=0, @DataAngPlJ datetime='', @DataAngPlS datetime='', @fltDataModif int=0, @DataModifJ datetime='', @DataModifS datetime='', 
	@oSub int=0, @cSub char(9)='', @SiModFctCOR int=0, @activitate varchar(20)=null) 
as
begin try
	declare @Bugetari int, @utilizator varchar(20), @lista_lm int, @multiFirma int, @doarPopulare int, 
	@dataSusAnt datetime, @dataJosNext datetime, @dataSusNext datetime, @DataRegistruPtAng datetime, @OreLuna int, @Dafora int, @Colas int

	set @Bugetari=dbo.iauParL('PS','UNITBUGET')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Colas=dbo.iauParL('SP','COLAS')
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

--	pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @dataSusAnt=DateAdd(day,-1, @dataJos)
	set @dataJosNext=DateAdd(day,1,@dataSus)
	set @dataSusNext=dbo.eom(DateAdd(day,1,@dataSus))

	if object_id('tempdb..#FunctiiCOR') is not null drop table #FunctiiCOR
	if object_id('tempdb..#StareCrtContracte') is not null drop table #StareCrtContracte
	if object_id('tempdb..#DateRevisalContracte') is not null drop table #DateRevisalContracte
	if object_id('tempdb..#tmpRevisalContracte') is not null drop table #tmpRevisalContracte
	if object_id('tempdb..#dataStare') is not null drop table #dataStare

--	determin intr-o variabila data de filtrare pt. angajatii noi 
--	(daca generez fisierul la data de vineri, sa-i aduca si pe cei angajati lunii+sarbatori legale)
	set @DataRegistruPtAng=DateAdd(day,1,@DataRegistru)
	if datename(WeekDay, @DataRegistruPtAng) in ('Saturday','Sunday') or @DataRegistruPtAng in (select data from calendar)
		while datename(WeekDay, @DataRegistruPtAng) in ('Saturday','Sunday') or @DataRegistruPtAng in (select data from calendar)
			Set @DataRegistruPtAng = dateadd(day, 1, @DataRegistruPtAng)

--	Creez tabela temporara in care extrag datele din extinfop si le aranjez pe coloana pt. fiecare salariat	
	create table #DateRevisalContracte (Marca char(6), Cod_inf char(13), Cetatenie varchar(80), TipContract varchar(60), DataSfarsit datetime, ExceptieDataSfarsit varchar(60), 
		IntervalTimp varchar(60), Durata int, Repartizare varchar(60), TemeiIncetare varchar(60), TextTemeiIncetare varchar(60), DetaliiContract varchar(60), 
		DataIncheiere datetime, DataConsemnare datetime, DataModificare datetime, Pasaport varchar(50), NumarContractVechi varchar(20), DataContractVechi datetime Unique (Marca, Cod_inf))
	insert into #DateRevisalContracte
	select Marca, max((case when Cod_inf='#CODCOR' then Cod_inf end)),
		isnull(substring(max((case when Cod_inf='RCETATENIE' then convert(char(10),Data_inf,111)+Val_inf end)),11,80),'Romana') as Cetatenie, 
		substring(max((case when Cod_inf='DATAINCH' then convert(char(10),Data_inf,111)+Val_inf end)),11,60) as TipContract,
		max((case when Cod_inf='DATASFCONDET' then Data_inf end)) as DataSfarsit,  
		isnull(substring(max((case when Cod_inf='EXCEPDATASF' then convert(char(10),Data_inf,111)+Val_inf end)),11,60),'') as ExceptieDataSfarsit,
		isnull(substring(max((case when Cod_inf='TIPINTREPTM' then convert(char(10),Data_inf,111)+Val_inf end)),11,60),'OrePeZi') as IntervalTimp,  
		isnull(max(case when Cod_inf='TIPINTREPTM' then Procent end),0) as Durata,  
		isnull(substring(max((case when Cod_inf='REPTIMPMUNCA' then convert(char(10),Data_inf,111)+Val_inf end)),11,60),'OreDeZi') as Repartizare,  
		substring(max((case when Cod_inf='RTEMEIINCET' then convert(char(10),Data_inf,111)+Val_inf end)),11,60) as TemeiIncetare,  
		substring(max((case when Cod_inf='TXTTEMEIINCET' then convert(char(10),Data_inf,111)+Val_inf end)),11,60) as TextTemeiIncetare,  
		substring(max((case when Cod_inf='CNTRDET' then convert(char(10),Data_inf,111)+Val_inf end)),11,60) as DetaliiContract,  
		max((case when Cod_inf='DATAINCH' then Data_inf end)) as DataIncheiere,  
		isnull(max((case when Cod_inf='MMODIFCNTR' then Data_inf end)),'01/01/1901') as DataConsemnare,
		max((case when Cod_inf in ('DATAMFCT','DATAMDCTR','CONDITIIM','SALAR','DATAMRL') then Data_inf end)) as DataModificare,
		isnull(max((case when Cod_inf='PASAPORT' then Val_inf end)),'') as Pasaport,
		isnull(max((case when Cod_inf='CONTRACTVECHI' then Val_inf end)),'') as NumarContractVechi,
		isnull(max((case when Cod_inf='DATACNTRVECHI' then Data_inf end)),'') as DataContractVechi
	from Extinfop
	where cod_inf in ('RCETATENIE','RTEMEIINCET','TXTTEMEIINCET','CONTRDET','DATAINCH','DATASFCONDET','EXCEPDATASF','TIPINTREPTM','REPTIMPMUNCA','MMODIFCNTR','PASAPORT','CONTRACTVECHI','DATACNTRVECHI')
			or cod_inf in ('DATAMFCT','DATAMDCTR','CONDITIIM','SALAR','DATAMRL') and Data_inf<=(case when @DataRegistruPtAng>@dataSus then @DataRegistruPtAng else @dataSus end)
	Group By Marca
	Create index marca on #DateRevisalContracte (Marca)

--	Formez functiile COR doar pt. functiile definite in ASiS
	create table #FunctiiCOR 
		(Cod_functie char(6), NumarCOR char(6), FunctieCOR varchar(6), DenumireCOR varchar(250))	
	insert into #FunctiiCOR
	select Marca, rtrim(e.Val_inf), f.Cod_functie, f.Denumire
	from Extinfop e, Functii_COR f 
	where Cod_inf in ('#CODCOR') and f.Cod_functie=e.Val_inf	
	create index cod_functie on #FunctiiCOR (Cod_functie)

--	pun datele returnate de procedura pRevisalStareContracte intr-o tabela temporara. 
	create table #StareCrtContracte
		(Data datetime, Marca char(6), StareContract char(50), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, TemeiLegal varchar(50), 
		AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate varchar(50))
	create index Principal on #StareCrtContracte (Data, Marca, StareContract,DataInceput)

	insert into #StareCrtContracte
	exec pRevisalStareContracte @dataJos=@dataJos, @dataSus=@dataSus, @Marca=@cMarca, @DataRegistru=@DataRegistru, @SiActiviIncetati=1, @SiUltimaStareAnt=0, @StarePrecedenta=0, @activitate=@activitate

	if OBJECT_ID('tempdb..#RevisalContracte') is null 
	Begin
		create table #RevisalContracte (NrCrt int identity (1,1))
		Exec CreeazaDiezRevisal @numeTabela='#RevisalContracte'
		set @doarPopulare=0
	End
	else 
		set @doarPopulare=1

	--declare tmpContracte cursor for
	select i.Data, i.Marca, (case when r.Cetatenie in ('Alta','UESEE') and r.Pasaport<>'' and p.cod_numeric_personal='' then r.Pasaport else p.Cod_numeric_personal end) as CNP, 
		(case when r.Cetatenie in ('Alta','UESEE') and r.Pasaport<>'' and p.cod_numeric_personal<>'' then r.Pasaport end) as CNPVechi, 
		p.Data_angajarii_in_unitate as DataAngajarii, isnull(i.Loc_de_munca,'') as Loc_de_munca, i.Data_plec as DataPlecarii, 
		isnull(i.Cod_functie,'') as Cod_functie, isnull(f1.FunctieCOR,'') as CodCOR, isnull(f2.FunctieCOR,'') as CodCORAnt, f1.DenumireCOR, 
		(case when i.mod_angajare='N' or i.mod_angajare='' then 'Nedeterminata' else 'Determinata' end) as TipDurata, 
		isnull((case when ia.mod_angajare='N' or ia.mod_angajare='' then 'Nedeterminata' else 'Determinata' end),'') as TipDurataAnt, 
		(case when i.Grupa_de_munca='C' then 'TimpPartial' else 'NormaIntreaga' end) as TipNorma, 
		isnull((case when ia.Grupa_de_munca='C' then 'TimpPartial' else 'NormaIntreaga' end),'') as TipNormaAnt, 
		(case when isnull(r.TipContract,'')<>'' then isnull(r.TipContract,'') else 'ContractIndividualMunca' end) as TipContract,
		(case when i.Grupa_de_munca='C' then (case when r.Durata<>0 then r.Durata else i.Salar_lunar_de_baza/(case when @Dafora=1 then dbo.iauParLN(i.Data,'PS','ORE_LUNA')/8 else 1 end) end) 
			else 0 end) as Durata,
		(case when ia.Grupa_de_munca='C' then ia.Salar_lunar_de_baza/(case when @Dafora=1 then dbo.iauParLN(ia.Data,'PS','ORE_LUNA')/8 else 1 end) else 0 end) as DurataAnt,
		(case when i.Grupa_de_munca='C' then isnull((case when r.IntervalTimp='' then 'OrePeZi' else r.IntervalTimp end),
		(case when i.Grupa_de_munca='C' then 'OrePeZi' else '' end)) end) as IntervalTimp,
		(case when i.Grupa_de_munca='C' then 'TimpPartial' when i.Salar_lunar_de_baza=6 then 'NormaIntreaga630' else 'NormaIntreaga840' end) as Norma, 
		isnull((case when ia.Grupa_de_munca='C' then 'TimpPartial' when ia.Salar_lunar_de_baza=6 then 'NormaIntreaga630' else 'NormaIntreaga840' end),'') as NormaAnt, 
		isnull((case when r.Repartizare='' then 'OreDeZi' else r.Repartizare end),'OreDeZi') as Repartizare,
		(case when charindex('-',ip.Nr_contract)<>0 then left(ip.Nr_contract,charindex('-',ip.Nr_contract)-1) 
			when charindex('/',ip.Nr_contract)<>0 and @Colas=0 
--	daca din sirul obtinut de dupa primul / am doua caractere / sau . inseamna ca in numarul de contract apare si data, caz in care aceasta se elimina
			and (len(substring(ip.Nr_contract,charindex('/',ip.Nr_contract)+1,20))-len(replace(substring(ip.Nr_contract,charindex('/',ip.Nr_contract)+1,20),'/',''))=2
				or len(substring(ip.Nr_contract,charindex('/',ip.Nr_contract)+1,20))-len(replace(substring(ip.Nr_contract,charindex('/',ip.Nr_contract)+1,20),'.',''))=2)
			then left(ip.Nr_contract,charindex('/',ip.Nr_contract)-1) else ip.Nr_contract end) as NumarContract,
		r.NumarContractVechi,r.DataContractVechi, 
		p.Data_angajarii_in_unitate as DataInceputContract,
		(case when i.mod_angajare='D' then (case when nullif(r.DataSfarsit,'01/01/1901') is not null then r.DataSfarsit else i.Data_plec end) else '01/01/1901' end) as DataSfarsitContract, 
		(case when i.mod_angajare='D' then isnull(r.ExceptieDataSfarsit,'') else '' end) as ExceptieDataSfarsit, i.Salar_de_incadrare as Salar, 
		isnull(rtrim(r.TemeiIncetare),'') as TemeiIncetare, 
		(case when /*convert(char(1),p.loc_ramas_vacant)='1' and month(p.Data_plec)=month(i.data) and year(p.Data_plec)=year(i.data) then p.Data_plec*/
			 sc.StareContract='ContractStareIncetare' then sc.DataIncetare else '01/01/1901' end) as DataIncetareContract,'' as TemeiReactivare,'01/01/1901' as DataReactivare,
		isnull(r.TextTemeiIncetare,'') as TextTemeiIncetare,isnull(r.DetaliiContract,'') as DetaliiContract,
		isnull(r.DataIncheiere,p.Data_angajarii_in_unitate) as DataIncheiereContract,
		isnull((case when dbo.data_maxima(sc.DataInceput,r.DataModificare)>r.DataConsemnare then dbo.data_maxima(sc.DataInceput,r.DataModificare) 
			when DataConsemnare='01/01/1901' then convert(datetime,convert(char(10),getdate(),101)) 
			else DataConsemnare end),convert(datetime,convert(char(10),getdate(),101))) as DataConsemnare, 
		sc.StareContract as StareCurenta, sc.DataInceput as DataIncStareCurenta, sc.TemeiLegal
	into #tmpRevisalContracte
	from istpers i 
		left outer join personal p on i.marca=p.marca
		left outer join infopers ip on i.marca=ip.marca
		left outer join istPers ia on ia.Marca=i.Marca and ia.Data=@dataSusAnt
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
		inner join #DateRevisalContracte r on r.Marca=i.Marca
		left outer join #StareCrtContracte sc on i.Marca=sc.Marca
		left outer join #FunctiiCOR f1 on f1.Cod_functie=i.Cod_functie
		left outer join #FunctiiCOR f2 on f2.Cod_functie=ia.Cod_functie
	where ((i.data=@dataSus or i.Data=@dataSusNext and p.Data_angajarii_in_unitate>@dataSus) --and (convert(char(1),p.loc_ramas_vacant)='0' or (p.Data_plec>=@DataRegistru or p.Data_plec>=@dataJos))
			or convert(char(1),p.loc_ramas_vacant)='1' and i.Data<@dataJos and (i.Data>'08/01/2011' or @multiFirma=1 and r.DataIncheiere>='01/01/2013') 
				and MONTH(i.Data)=MONTH(p.Data_plec) and year(i.Data)=year(p.Data_plec))
		and (@oMarca=0 or i.marca=@cMarca) and (p.Data_angajarii_in_unitate<=@DataRegistruPtAng or r.DataIncheiere<=@DataRegistru)
		and (@unLM=0 or i.Loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%'else '' end)) 
		and i.Grupa_de_munca not in ('O','P','') and i.mod_angajare<>'R'
		and (@Judet='' or p.judet=@Judet) 
		and (@fltDataAngPl=0 or p.Data_angajarii_in_unitate between @DataAngPlJ and @DataAngPlS or convert(char(1),p.loc_ramas_vacant)='1' and i.Data_plec between @DataAngPlJ and @DataAngPlS)
		and (@fltDataModif=0  or isnull((case when r.DataModificare>r.DataConsemnare then r.DataModificare else r.DataConsemnare end),'01/01/1901') between @DataModifJ and @DataModifS) 
		and (@Bugetari=0 or convert(int,ip.Actionar)=0)		
		and (@oSub=0 or exists (select 1 from proprietati pr where pr.cod=i.marca and pr.tip='PERSONAL' and pr.cod_proprietate='SUBUNITATE' and pr.valoare=@cSub))
		and (@activitate is null or p.Activitate=@activitate)
		and (@lista_lm=0 or lu.cod is not null) 
		and p.Mod_angajare<>'F'
	order by i.marca, i.data

	Create table #DataStare (marca varchar(6), dataStare datetime, siUltimaStare int)
	insert into #DataStare 
	select marca, (case when StareCurenta='ContractStareSuspendare' and TemeiLegal='Art52Alin1LiteraD' then DataIncStareCurenta else DateADD(day,-1,DataIncStareCurenta) end), 
		(case when StareCurenta='ContractStareActiv' then 1 else 0 end)
	from #tmpRevisalContracte

--	creez tabela temporara in care scriu data starii curente, functie de care, prin procedura pRevisalStareContracte se va stabili stare precedenta.
	create table #StarePrecedContracte
		(Data datetime, Marca char(6), StareContract char(50), DataInceput datetime, DataSfarsit datetime, DataIncetare datetime, TemeiLegal varchar(50), 
		AngajatorCui varchar(50), AngajatorNume varchar(50), Nationalitate varchar(50))
	create index Principal on #StarePrecedContracte (Data, Marca, StareContract, DataInceput)

	insert into #StarePrecedContracte
	exec pRevisalStareContracte @dataJos=@dataJos, @dataSus=@dataSus, @Marca=@cMarca, @DataRegistru=@DataRegistru, @SiActiviIncetati=0, @SiUltimaStareAnt=1, @StarePrecedenta=1, @activitate=@activitate

--	completez datele in tabela finala, inclusiv starea precedenta.
	insert into #RevisalContracte
	select a.Data, a.Marca, a.CNP, a.CNPVechi, a.DataAngajarii, a.Loc_de_munca, a.DataPlecarii, a.Cod_functie, 
		a.CodCOR, (case when a.CodCOR<>a.CodCORAnt and a.CodCORAnt<>'' then a.CodCORAnt else '' end), a.DenumireCOR, 
		a.TipDurata, (case when a.TipDurata<>a.TipDurataAnt and a.TipDurataAnt<>'' then a.TipDurataAnt else '' end), 
		a.TipNorma, (case when a.TipNorma<>a.TipNormaAnt and a.TipNormaAnt<>'' then a.TipNormaAnt else '' end), a.TipContract, 
		a.Durata, (case when a.Durata<>a.DurataAnt and a.DurataAnt<>0 then a.DurataAnt else 0 end), a.IntervalTimp, 
		a.Norma, (case when a.Norma<>a.NormaAnt and a.NormaAnt<>'' then a.NormaAnt else '' end), a.Repartizare, 
		a.NumarContract, a.NumarContractVechi, a.DataContractVechi, a.DataInceputContract, a.DataSfarsitContract, a.ExceptieDataSfarsit, 
		a.Salar, a.TemeiIncetare, a.DataIncetareContract, a.TemeiReactivare, a.DataReactivare, a.TextTemeiIncetare, a.DetaliiContract, a.DataIncheiereContract, 
		a.StareCurenta, a.DataIncStareCurenta, isnull(sp.StareContract,'') as StarePrecedenta, isnull(sp.DataIncetare,'01/01/1901') as DataIncetareStarePrecedenta, a.DataConsemnare, a.TemeiLegal
	from #tmpRevisalContracte a
		left outer join #StarePrecedContracte sp on sp.marca=a.marca 

	if exists (select * from sysobjects where name ='genRevisalContracteSP' and xtype='P')
		exec genRevisalContracteSP @dataJos=@dataJos, @dataSus=@dataSus, @DataRegistru=@DataRegistru

	if @doarPopulare=0
	select NrCrt, Data, Marca, CNP, CNPVechi, DataAngajarii, Loc_de_munca, DataPlecarii, Cod_functie, CodCOR, CodCORAnt, DenumireCOR, TipDurata, TipDurataAnt, TipNorma, TipNormaAnt, 
		TipContract, Durata, DurataAnt, IntervalTimp, Norma, NormaAnt, Repartizare, NumarContract, NumarContractVechi, DataContractVechi, DataInceputContract, DataSfarsitContract, ExceptieDataSfarsit, 
		Salar, TemeiIncetare, DataIncetareContract, TemeiReactivare, DataReactivare, TextTemeiIncetare, DetaliiContract, DataIncheiereContract, StareCurenta, 
		DataIncStareCurenta, StarePrecedenta, DataIncetareStarePrecedenta, DataConsemnare, TemeiLegal
	from #RevisalContracte
end try 

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura genRevisalContracte (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec genRevisalContracte '02/01/2014', '02/28/2014', '02/28/2014', 0, '', 0, '', 0, '', '', 0, '', '', 0, '', '', 0, '', 0
*/
