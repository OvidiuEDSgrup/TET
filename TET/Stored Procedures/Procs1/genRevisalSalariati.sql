--***
/**	procedura pt. registru electronic de salariati - date salariati */
Create procedure genRevisalSalariati
	(@dataJos datetime, @dataSus datetime, @DataRegistru datetime, @oMarca int=0, @cMarca char(6)='', @unLm int=0, @Lm char(9)='', @Strict int=0, @SirMarci varchar(1000)='', 
	@Judet varchar(15)='', @fltDataAngPl int=0, @DataAngPlJ datetime='', @DataAngPlS datetime='', @fltDataModif int=0, @DataModifJ datetime='', @DataModifS datetime='', 
	@oSub int=0, @cSub char(9)='', @activitate varchar(20)=null) 
as
begin
	declare @Bugetari int, @utilizator varchar(20), @lista_lm int, @multiFirma int, @doarPopulare int, 
		@Luna int, @An int, @dataSusAnt datetime, @dataJosNext datetime, @dataSusNext datetime, @DataRegistruPtAng datetime
	set @Bugetari=dbo.iauParL('PS','UNITBUGET')
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator=dbo.fIaUtilizator(null)
	select @Luna=month(@dataSus), @An=year(@dataSus)
	set @dataSusAnt=DateAdd(day,-1,@dataJos)
	set @dataJosNext=DateAdd(day,1,@dataSus)
	set @dataSusNext=dbo.eom(DateAdd(day,1,@dataSus))
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

--	determin intr-o variabila data de filtrare pt. angajatii noi 
--	(daca generez fisierul la data de vineri, sa-i aduca si pe cei angajati lunii+sarbatori legale)
	set @DataRegistruPtAng=DateAdd(day,1,@DataRegistru)
	if datename(WeekDay, @DataRegistruPtAng) in ('Saturday','Sunday') or @DataRegistruPtAng in (select data from calendar)
		while datename(WeekDay, @DataRegistruPtAng) in ('Saturday','Sunday') or @DataRegistruPtAng in (select data from calendar)
			Set @DataRegistruPtAng = dateadd(day, 1, @DataRegistruPtAng)

	if object_id('tempdb..#DateRevisalSal') is not null drop table #DateRevisalSal
	if object_id('tempdb..#tmpRevisalSalariati') is not null drop table #tmpRevisalSalariati

--	Creez tabela temporara in care extrag datele din extinfop si le aranjez pe coloana pt. fiecare salariat; merge mai rapid decat cu subselect
	create table #DateRevisalSal (Marca char(6), TipActIdentitate varchar(80), Cetatenie varchar(80), Nationalitate nvarchar(80), Mentiuni varchar(80), CodSiruta varchar(80), 
		DataIncheiere datetime, DataConsemnare datetime, DataModificare datetime, Pasaport varchar(50) Unique (Marca))
	insert into #DateRevisalSal
	select Marca, 
		isnull(substring(max((case when Cod_inf='RTIPACTIDENT' then convert(char(10),Data_inf,111)+Val_inf end)),11,80),'CarteIdentitate') as TipActIdentitate, 
		isnull(substring(max((case when Cod_inf='RCETATENIE' then convert(char(10),Data_inf,111)+Val_inf end)),11,80),'Romana') as Cetatenie, 
		isnull(substring(max((case when Cod_inf='RCODNATIONAL' then convert(char(10),Data_inf,111)+Val_inf end)),11,80),'România') as Nationalitate, 
		isnull(substring(max((case when Cod_inf='MENTIUNI' then convert(char(10),Data_inf,111)+Val_inf end)),11,80),'') as Mentiuni,
		isnull(substring(max((case when Cod_inf='CODSIRUTA' then convert(char(10),Data_inf,111)+Val_inf end)),11,80),'') as CodSiruta,
		isnull(max((case when Cod_inf='DATAINCH' then Data_inf end)),'01/01/1901') as DataIncheiere,  
		isnull(max((case when Cod_inf='MMODIFCNTR' then Data_inf end)),'01/01/1901') as DataConsemnare,
		isnull(max((case when Cod_inf in ('DATAMFCT','DATAMDCTR','CONDITIIM','SALAR','DATAMRL') then Data_inf end)),'01/01/1901') as DataModificare,
		isnull(max((case when Cod_inf='PASAPORT' then Val_inf end)),'') as Pasaport
	from Extinfop 
	where cod_inf in ('RTIPACTIDENT','RCETATENIE','RCODNATIONAL','MENTIUNI','CODSIRUTA','DATAINCH','MMODIFCNTR','DATAMFCT','DATAMDCTR','CONDITIIM','SALAR','DATAMRL','PASAPORT')
	Group By Marca
	Create index marca on #DateRevisalSal (Marca)

	update #DateRevisalSal set Nationalitate=N'Federaţia Rusă' where Nationalitate='Federatia Rusa'

	if OBJECT_ID('tempdb..#RevisalSalariati') is null 
	Begin
		create table #RevisalSalariati (NrCrt int identity (1,1))
		Exec CreeazaDiezRevisal @numeTabela='#RevisalSalariati'
		set @doarPopulare=0
	End
	else 
		set @doarPopulare=1

	select i.Data, i.Marca, left(i.Nume, charindex(' ',i.Nume)) as Nume, substring(i.Nume,charindex(' ',i.Nume)+1,25) as Prenume, 
		left(ia.Nume, charindex(' ',ia.Nume)) as NumeAnt, substring(ia.Nume,charindex(' ',ia.Nume)+1,25) as PrenumeAnt, 
		(case when r.Cetatenie in ('Alta','UESEE') and r.Pasaport<>'' and p.cod_numeric_personal='' then r.Pasaport else p.Cod_numeric_personal end) as CNP, 
		(case when r.Cetatenie in ('Alta','UESEE') and r.Pasaport<>'' and p.cod_numeric_personal<>'' then r.Pasaport end) as CNPVechi, 
		isnull((case when r.Cetatenie='' then 'Romana' else r.Cetatenie end),'Romana') as Cetatenie, 
		isnull((case when r.Nationalitate='' then 'România' else r.Nationalitate end),'România') as Nationalitate, 
		isnull(r.TipActIdentitate,'CarteIdentitate') as TipActIdentitate, isnull(r.Mentiuni,'') as Mentiuni, isnull(d.cod_postal,'') as CodSiruta, 
		'Loc. '+rtrim(i.Localitate)+' strada '+rtrim(i.Strada)+' nr. ' +rtrim(i.Numar)+(case when i.Bloc<>'' then ' bloc '+rtrim(i.Bloc) else '' end)
			+(case when i.Scara<>'' then ' scara '+rtrim(i.Scara) else '' end) +(case when i.Apartament<>'' then ' ap. '+rtrim(i.Apartament) else '' end)
			+(case when i.Cod_postal<>0 then ' CP. '+rtrim(i.Cod_postal) else '' end) 
			+(case when i.Sector<>0 then ' sector '+rtrim(convert(char(1),i.Sector)) else '' end) as Adresa, 
		'Strada '+rtrim(ia.Strada)+' nr. ' +rtrim(ia.Numar)+(case when ia.Bloc<>'' then ' bloc '+rtrim(ia.Bloc) else '' end)
			+(case when ia.Scara<>'' then ' scara '+rtrim(ia.Scara) else '' end) +(case when ia.Apartament<>'' then ' ap. '+rtrim(ia.Apartament) else '' end)
			+(case when ia.Sector<>0 then ' sector '+rtrim(convert(char(1),ia.Sector)) else '' end) as AdresaAnt, i.Localitate, 
		isnull((case when r.DataModificare>r.DataConsemnare then r.DataModificare when DataConsemnare='01/01/1901' then convert(datetime,convert(char(10),getdate(),101)) 
			else DataConsemnare end),convert(datetime,convert(char(10),getdate(),101))) as DataConsemnare, 
		isnull(z.TipAutorizatie,'marca cu probl:'+i.marca) as TipAutorizatie, isnull(z.DataInceput,'01/01/1901') as DataInceputAutoriz, isnull(z.DataSfarsit,'01/01/1901') DataSfarsitAutoriz
	into #tmpRevisalSalariati
	from istpers i 
		left outer join istPers ia on ia.Marca=i.Marca and ia.Data=dbo.eom(DateAdd(month,-1,i.Data)) --@dataSusAnt
		inner join personal p on i.marca = p.marca 
		left outer join infopers ip on i.marca = ip.marca
		left outer join proprietati pr on i.marca = pr.cod and pr.tip='PERSONAL' and pr.cod_proprietate='SUBUNITATE'
		inner join #DateRevisalSal r on r.Marca=i.Marca
		left outer join localitati d on d.cod_oras = r.CodSiruta
		left outer join fRevisalAutorizatii (@dataJos, @dataSus, @cMarca) z on z.Marca=i.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where ((i.data=@dataSus or i.Data=@dataSusNext and p.Data_angajarii_in_unitate>@dataSus) --and (convert(char(1),p.loc_ramas_vacant)='0' or (p.Data_plec>=@DataRegistru or p.Data_plec>=@dataJos)) 
			or convert(char(1),p.loc_ramas_vacant)='1' and i.Data<@dataJos and (i.Data>'08/01/2011' or @multiFirma=1 and r.DataIncheiere>='01/01/2013') 
				and MONTH(i.Data)=MONTH(p.Data_plec) and year(i.Data)=year(p.Data_plec)) 
		and (@oMarca=0 or i.marca=@cMarca) and (@unLm=0 or i.Loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%'else '' end)) 
		and (@Bugetari=0 or convert(int,ip.Actionar)=0) and (p.Data_angajarii_in_unitate<=@DataRegistruPtAng or r.DataIncheiere<=@DataRegistru)
		and (@SirMarci='' or charindex(','+rtrim(ltrim(i.marca))+',',@SirMarci)>0) and (@Judet='' or p.judet=@Judet) 
		and (@fltDataAngPl=0 or p.data_angajarii_in_unitate between @DataAngPlJ and @DataAngPlS or convert(char(1),p.loc_ramas_vacant)='1' and i.data_plec between @DataAngPlJ and @DataAngPlS)
		and (@fltDataModif=0 or isnull((case when r.DataModificare>r.DataConsemnare then r.DataModificare else r.DataConsemnare end),'01/01/1901') between @DataModifJ and @DataModifS) 
		and i.grupa_de_munca not in ('O','P','') and i.mod_angajare<>'R' and p.Mod_angajare<>'F'
		and (@oSub=0 or isnull(pr.valoare,'')=@cSub)
		and (@activitate is null or p.Activitate=@activitate)
		and (@lista_lm=0 or lu.cod is not null) 
	order by i.marca, i.data

	insert into #RevisalSalariati
	select Data, Marca, Nume, Prenume, NumeAnt, PrenumeAnt, CNP, CNPVechi, Cetatenie, Nationalitate, TipActIdentitate, Mentiuni, CodSiruta, 
			Adresa, AdresaAnt, Localitate, DataConsemnare, TipAutorizatie, DataInceputAutoriz, DataSfarsitAutoriz
	from (select Data, Marca, Nume, Prenume, NumeAnt, PrenumeAnt, CNP, CNPVechi, Cetatenie, Nationalitate, TipActIdentitate, Mentiuni, CodSiruta, 
			Adresa, AdresaAnt, Localitate, DataConsemnare, TipAutorizatie, DataInceputAutoriz, DataSfarsitAutoriz, 
			ROW_NUMBER() OVER (PARTITION BY CNP ORDER BY DATA DESC,MARCA) as OrdineCNP
		from #tmpRevisalSalariati) a
	where a.OrdineCNP=1

	if exists (select * from sysobjects where name ='genRevisalSalariatiSP' and xtype='P')
		exec genRevisalSalariatiSP @dataJos=@dataJos, @dataSus=@dataSus, @DataRegistru=@DataRegistru

	if @doarPopulare=0
	select NrCrt, Data, Marca, Nume, Prenume, NumeAnt, PrenumeAnt, CNP, CNPVechi, Cetatenie, Nationalitate, TipActIdentitate, Mentiuni, CodSiruta, Adresa, AdresaAnt, 
		Localitate, DataConsemnarii, TipAutorizatie, DataInceputAutorizatie, DataSfarsitAutorizatie
	from #RevisalSalariati

end
/*
	exec genRevisalSalariati '02/01/2014', '02/28/2014', '02/28/2014', 0, '', 0, '', 0, '', '', 0, '', '', 0, '', '', 0, ''
*/
