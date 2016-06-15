--***
create procedure wIaVerificareDLSalarii @sesiune varchar(50), @parXML XML, @rezultat xml=null output
as   
-- apelare procedura specifica daca aceasta exista.
/*
	tipuri de validari
	Tip_validare='CE' -> 'Coduri eronate'  (marca, functie, loc de munca, cnp, casa de sanatate inexistente in cataloage/eronate)
	Tip_validare='SI' -> 'Date eronate pt. salariati inactivi' (exista date salarii in afara perioadei lucrate in unitate)
	Tip_validare='RV' -> 'Date revisal' 
	Tip_validare='DP' -> 'Date personal de modificat' (validare regim de lucru pt. salariati ce au implinit/vor implini 18 ani) 
	Tip_validare='NP' -> 'Necorelatie pontaj-concedii' (necorelatie intre ore din pontaj si zile din tabelele de concedii)
	Tip_validare='SN' -> 'Salariati nepontati' 
	Tip_validare='PE' -> 'Pontati eronat' (ore justificate din pontaj difera de orele lucratoare din luna)
*/
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaVerificareDLSalariiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaVerificareDLSalariiSP @sesiune, @parXML output
	return @returnValue
end 
begin try
	set transaction isolation level read uncommitted
	declare @tip varchar(2), @dataJos datetime, @dataSus datetime, @utilizator varchar(20), @sub varchar(9), @tipValidare varchar(100), 
		@formaJuridica varchar(100), @carduri int, @listaBanci varchar(200), @listaBanci1 varchar(200), @listaBanci2 varchar(200), @NCHand int, @MachetaCO int, @COEvenInMachetaCO int, 
		@mesajeroare varchar(500), @filtruValidare varchar(50), @filtruMarca varchar(50), @filtruLM varchar(30), @filtruExplicatii varchar(50), @cDataSus varchar(10)
		
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'GE', 'FJURIDICA', 0, 0, @formaJuridica output
	exec luare_date_par 'PS', 'CARDBANCA', @carduri output, 0, @listaBanci1 output
	exec luare_date_par 'PS', 'CARDBANCB', 0, 0, @listaBanci2 output
	exec luare_date_par 'PS', 'NC-CPHAND', @NCHand output, 0, ''
	exec luare_date_par 'PS', 'OPZILECOM', @MachetaCO output, 0, ''
	exec luare_date_par 'PS', 'COEVMCO', @COEvenInMachetaCO output, 0, ''

--	citire date din xml
	select 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@dataJos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@dataSus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@tipValidare = isnull(@parXML.value('(/row/@tipvalidare)[1]','varchar(100)'),''),
		@filtruMarca = isnull(@parXML.value('(/row/@f_marca)[1]','varchar(50)'),''),
		@filtruLM = isnull(@parXML.value('(/row/@f_lm)[1]','varchar(30)'),''),
		@filtruValidare = isnull(@parXML.value('(/row/@f_validare)[1]','varchar(50)'),''),
		@filtruExplicatii = isnull(@parXML.value('(/row/@f_explicatii)[1]','varchar(50)'),'')		
	
	set @cDataSus=CONVERT(char(10),@dataSus,103)
	IF OBJECT_ID('tempdb..#necorelatii') IS NOT NULL drop table #necorelatii
	IF OBJECT_ID('tempdb..#personal') IS NOT NULL drop table #personal
	IF OBJECT_ID('tempdb..#personalcnp') IS NOT NULL drop table #personalcnp
	IF OBJECT_ID('tempdb..#pontaj') IS NOT NULL drop table #pontaj
	IF OBJECT_ID('tempdb..#conalte') IS NOT NULL drop table #conalte
	
	create table #necorelatii(
		Tip_validare char(2) not null,
		Tabela char(25) not null,
		Camp char(25) not null,
		Data datetime not null,
		Marca char(6) not null,
		Continut char(20) not null,
		Explicatii char(150) not null,
		Loc_de_munca char(9) not null,
		Valoare_1 float,
		Valoare_2 float
	) 
	CREATE UNIQUE CLUSTERED INDEX Unic ON #necorelatii (Tip_validare, Tabela, Camp, Data, Marca, Continut, Explicatii)
--	creez tabela temporara din personal in care nu pun marcile pe care se opereaza doar deconturi, predari in folosinta prin 482, etc
	select * into #personal from personal
	where isnull(fictiv,0)=0 and (convert(int,Loc_ramas_vacant)=0 or Data_plec>=@dataJos)

	select dbo.eom(a.data) as data, a.marca as marca, max(a.Loc_de_munca) as loc_de_munca, 
		convert(decimal(10,2),sum(ore_concediu_medical/regim_de_lucru)) as zile_cm, 
		convert(decimal(10,2),sum(Ore_concediu_de_odihna/regim_de_lucru)) as zile_co, 
		convert(decimal(10,2),sum(Ore_obligatii_cetatenesti/regim_de_lucru)) as zile_obligatii, 
		convert(decimal(10),sum(ore_nemotivate)) as ore_nemotivate,
		convert(decimal(10),sum(ore_invoiri)) as ore_invoiri,
		convert(decimal(10,2),sum(ore_concediu_fara_salar/regim_de_lucru)) as zile_cfs
	into #pontaj
	from pontaj a
	where a.data between @dataJos and @dataSus 
	group by dbo.eom(a.data), a.marca
	
--	validari coduri eronate
--	validare marci eronate
	insert into #necorelatii 
	select 'CE', 'istPers' as tabela, 'Marca' as camp, i.Data as data, i.marca as marca, i.marca as continut, 
		'Marca inexistenta!' as explicatii, i.Loc_de_munca as lm, 0, 0
	from istpers i 
	where i.data between @dataJos and @dataSus and not exists (select marca from personal p where p.Marca=i.marca)
	union all
	select 'CE', 'Pontaj', 'Marca', p.data, p.marca, p.marca, 'Marca inexistenta!', p.Loc_de_munca as lm, 0, 0
	from pontaj p 
	where p.data between @dataJos and @dataSus and not exists (select marca from personal where Marca=p.Marca)
	union all
	select 'CE', 'Brut', 'Marca', b.data, b.marca, b.marca, 'Marca inexistenta!', b.Loc_de_munca as lm, 0, 0
	from brut b 
	where b.data between @dataJos and @dataSus and not exists (select marca from personal p where p.Marca=b.Marca)
	union all
	select 'CE', 'Net', 'Marca', n.data, n.marca, n.marca, 'Marca inexistenta!', n.Loc_de_munca as lm, 0, 0
	from net n 
	where n.data between @dataJos and @dataSus and not exists (select marca from personal p where p.Marca=n.Marca)
	union all
	select 'CE', 'Realcom', 'Marca', r.data, r.marca, r.marca, 'Marca inexistenta!', r.Loc_de_munca as lm, 0, 0
	from realcom r 
	where r.data between @dataJos and @dataSus and r.marca<>'' and not exists (select marca from personal p where p.Marca=r.Marca)
	union all
	select 'CE', 'Retineri', 'Marca', r.data, r.marca, r.marca, 'Marca inexistenta!', i.Loc_de_munca as lm, 0, 0
	from resal r 
		left outer join istpers i on r.data=i.data and r.marca=i.marca 
	where r.data between @dataJos and @dataSus and not exists (select marca from personal p where p.Marca=r.Marca)
	union all
	select 'CE', 'Corectii', 'Marca', c.data, c.marca, c.marca,  'Marca inexistenta!', c.Loc_de_munca as lm, 0, 0
	from corectii c 
		left outer join istpers i on c.data=i.data and c.marca=i.marca 
	where c.data between @dataJos and @dataSus and c.marca<>'' and not exists (select marca from personal p where p.Marca=c.Marca)

--	validare locuri de munca
	insert into #necorelatii
	select 'CE', 'Personal', 'Loc de munca', @dataSus, p.marca, p.loc_de_munca, 'Loc de munca inexistent!', p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where not exists (select cod from lm where Cod=p.loc_de_munca)
	union all
	select 'CE', 'Pontaj', 'Loc de munca', p.data, p.marca, p.loc_de_munca, 'Loc de munca inexistent!', p.Loc_de_munca as lm, 0, 0
	from pontaj p 
	where p.data between @dataJos and @dataSus and not exists (select cod from lm where Cod=p.Loc_de_munca)
	union all
	select 'CE', 'Brut', 'Loc de munca', b.data, b.marca, b.loc_de_munca, 'Loc de munca inexistent!', b.Loc_de_munca as lm, 0, 0
	from brut b 
	where b.data between @dataJos and @dataSus and not exists (select cod from lm where Cod=b.loc_de_munca)
	union all
	select 'CE', 'Net', 'Loc de munca', n.data, n.marca, n.loc_de_munca, 'Loc de munca inexistent!', n.Loc_de_munca as lm, 0, 0
	from net n 
	where n.data between @dataJos and @dataSus and not exists (select cod from lm where Cod=n.loc_de_munca) 
	union all
	select 'CE', 'Realcom', 'Loc de munca', r.data, r.marca, r.loc_de_munca, 'Loc de munca inexistent!', r.Loc_de_munca as lm, 0, 0
	from realcom r 
	where r.data between @dataJos and @dataSus and not exists (select cod from lm where Cod=r.loc_de_munca) 
	union all
	select 'CE', 'Reallmun', 'Loc de munca', r.data, '', r.loc_de_munca, 'Loc de munca inexistent!', r.Loc_de_munca as lm, 0, 0
	from reallmun r 
	where r.data between @dataJos and @dataSus and not exists (select cod from lm where Cod=r.loc_de_munca)

--	validare cod functie
	insert into #necorelatii
	select 'CE', 'Personal', 'Cod functie', @dataSus, p.marca, p.cod_functie, 'Cod functie inexistent!', p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where not exists (select f.Cod_functie from functii f where f.Cod_functie=p.cod_functie)
	union all
	select 'CE', 'Istoric personal', 'Cod functie', i.Data, i.marca, i.cod_functie, 'Cod functie inexistent!', i.Loc_de_munca as lm, 0, 0
	from istpers i 
	where i.data between @dataJos and @dataSus and not exists (select f.Cod_functie from functii f where f.Cod_functie=i.cod_functie)

--	validare banca salariati
	insert into #necorelatii
	select 'CE', 'Personal', 'Banca', @dataSus, p.marca, p.Banca, 'Banca necompletata sau inexistenta in lista de banci definita!', p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where CHARINDEX(RTRIM(p.Banca),@listaBanci)=0 --and p.Banca<>'CASA' and p.Banca<>'NECOMPLETAT' and p.Banca<>''

--	validare Cont in banca salariati
	insert into #necorelatii
	select 'CE', 'Personal', 'Cont in banca', @dataSus, p.marca, p.cont_in_banca, 'Cont card necompletat!', p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where @carduri=1 and p.Cont_in_banca='' and p.Banca not like 'CASA%' and p.Banca<>'NECOMPLETAT' and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos)	--and p.Banca<>''

--	pun in tabela temporara doar salariatii pt. care trebuie validat CNP-ul (nu e cazul la salariatii de Nationalitate straina, decat cei cu Carte de rezidenta).
	select p.* into #personalcnp 
	from #personal p
		left outer join extinfop nat on nat.Marca=p.Marca and nat.Cod_inf='RCODNATIONAL' and nat.Val_inf<>''
		left outer join extinfop ta on ta.Marca=p.Marca and ta.Cod_inf='RTIPACTIDENT' and ta.Val_inf<>''
	where isnull(nat.Val_inf,'')='' or isnull(nat.Val_inf,'')='Rom�nia' or isnull(ta.Val_inf,'')='CarteDeRezidenta'
--	validare cod numeric personal
	insert into #necorelatii
	select 'CE', 'Personal', 'CNP', @dataSus, p.marca, p.cod_numeric_personal, 'CNP necompletat!', p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where p.cod_numeric_personal='' 
	union all 
	select 'CE', 'Personal', 'CNP', @dataSus, p.marca, p.cod_numeric_personal, 'CNP eronat!', p.Loc_de_munca as lm, 0, 0
	from #personalcnp p 
	where dbo.validare_cnp(p.cod_numeric_personal)='1'
	union all 
	select 'CE', 'Pers. intretin.', 'CNP pers. intr.', a.Data, p.marca, p.cod_numeric_personal, 'CNP eronat!', p.Loc_de_munca as lm, 0, 0
	from persintr a 
		left outer join personal p on p.Marca=a.Marca
	where dbo.validare_cnp(a.Cod_personal)='1' and a.data between @dataJos and @dataSus 

--	validare casa de sanatate salariati	
	insert into #necorelatii
	select 'CE', 'Personal', 'Casa de sanatate - adresa', @dataSus, p.marca, 
		(case when charindex(',',p.adresa)<>0 then ltrim(rtrim(substring(p.adresa,charindex(',',p.adresa)+1,3))) else p.adresa end), 'Casa de sanatate inexistenta!', 
		p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where (case when charindex(',',p.adresa)<>0 then ltrim(rtrim(substring(p.adresa,charindex(',',p.adresa)+1,3))) else left(p.adresa,2) end) 
		not in (select marca from extinfop where cod_inf='#CASSAN')

--	validare regim de lucru din pontaj
	insert into #necorelatii
	select distinct 'CE', 'Pontaj' as tabela, 'Regim lucru' as camp, max(a.data) as data, a.marca as marca, max(a.Regim_de_lucru) as continut, 
		'Regim de lucru pontaj = 0!' as explicatii, a.Loc_de_munca as lm, 0, 0
	from pontaj a
		left outer join istpers i on a.marca=i.marca and dbo.eom(a.data)=i.data
	where a.data between @dataJos and @dataSus and a.Regim_de_lucru=0
	group by a.data, a.marca, a.loc_de_munca, numar_curent

--	validare comenzi
	insert into #necorelatii
	select 'CE', 'Realizari com.', 'Comanda', r.data, r.marca, r.Comanda, 'Comanda inexistenta!', r.Loc_de_munca as lm, 0, 0 
	from realcom r 
		left outer join istpers i on r.data=i.data and r.marca=i.marca
	where r.data between @dataJos and @dataSus and r.marca<>'' and r.comanda<>'' and not exists (select comanda from comenzi where Subunitate=@sub and Comanda=r.comanda)
	union all
	select distinct 'CE', 'Realizari com.', 'Comanda', r.data, '', r.Comanda, 'Comanda inexistenta!', r.Loc_de_munca as lm, 0, 0 
	from realcom r 
	where r.data between @dataJos and @dataSus and r.marca='' and not exists (select comanda from comenzi where Subunitate=@sub and Comanda=r.comanda) and r.comanda<>''

--	cod beneficiar retinere
	insert into #necorelatii
	select 'CE', 'Retineri', 'Beneficiar retinere', r.data, r.marca, r.cod_beneficiar, 'Beneficiar retinere inexistent!', i.Loc_de_munca as lm, 0, 0
	from resal r 
		left outer join istpers i on r.data=i.data and r.marca=i.marca 
	where r.data between @dataJos and @dataSus and not exists (select cod_beneficiar from benret where Cod_beneficiar=r.cod_beneficiar)

--	corelatii date eronate pt. salariatii angajati/plecati
	insert into #necorelatii
	select distinct 'SI', 'Pontaj', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariatul angajat dupa '+@cdataSus+' !' end), 
		a.Loc_de_munca as lm, 0, 0 
	from pontaj a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Avans exceptie', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		p.Loc_de_munca, 0, 0 
	from avexcep a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Conc. medicale', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		p.Loc_de_munca, 0, 0 
	from conmed a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Concedii odihna', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		p.Loc_de_munca, 0, 0 
	from concodih a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Corectii', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat  angajat dupa '+@cdataSus+' !' end), 
		a.Loc_de_munca, 0, 0 
	from corectii a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and a.Marca<>'' and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Retineri', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		p.Loc_de_munca, 0, 0 
	from resal a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Tichete', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data_lunii, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		p.Loc_de_munca, 0, 0 
	from tichete a 
		left outer join personal p on a.marca=p.marca 
	where a.data_lunii between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Realizari com.', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		a.Loc_de_munca, 0, 0 
	from realcom a 
		left outer join personal p on a.marca=p.marca 
	where a.marca<>'' and a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Pers. intretin.', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		p.Loc_de_munca, 0, 0 
	from persintr a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Istoric pers.', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		a.Loc_de_munca, 0, 0 
	from istpers a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Net', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		a.Loc_de_munca, 0, 0 
	from Net a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)
	union all 
	select distinct 'SI', 'Brut', (case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Plecat' else 'Angajare' end), a.data, a.marca, a.marca, 
		(case when p.loc_ramas_vacant=1 and p.data_plec<@dataJos then 'Salariat plecat la '+convert(char(10),p.data_plec,103)+' !' else 'Salariat angajat dupa '+@cdataSus+' !' end), 
		a.Loc_de_munca, 0, 0 
	from brut a 
		left outer join personal p on a.marca=p.marca 
	where a.data between @dataJos and @dataSus and (p.loc_ramas_vacant=1 and p.data_plec<@dataJos or p.data_angajarii_in_unitate>@dataSus)

--	validare salariati care vor implini 18 ani si sunt incadrati cu regim de lucru mai mic de 8 ore si norma intreaga
	insert into #necorelatii
	select 'DP', 'Personal', 'Regimul de lucru', @dataSus, p.marca, p.Salar_lunar_de_baza, 
		(case when DATEDIFF(day,getdate(),DateADD(year,18,data_nasterii))<0 then 'Salariatul a implinit 18 ani. Se poate incadra cu 8 ore pe zi!'
			else 'Salariatul va implimi 18 ani in '+convert(char(3),DATEDIFF(day,getdate(),DateADD(year,18,data_nasterii)))+' zile! Va trebui incadrat cu 8 ore pe zi!' end), 
		p.Loc_de_munca as lm, 0, 0
	from #personal p 
	where p.Salar_lunar_de_baza>0 and p.Salar_lunar_de_baza<8 and p.Grupa_de_munca in ('N','D','S') and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos) 
		and abs(DATEDIFF(day,getdate(),DateADD(year,18,data_nasterii)))<30

--	date necompletate pentru registru electronic
	if @formaJuridica<>''
		insert into #necorelatii
		select 'RV' as Tip_validare, 'Pers/infopers/extinfop', 'Date revisal', a.Data, a.Marca, '', TipValidare, isnull(i.Loc_de_munca,p.Loc_de_munca),  0, 0
		from fValidariRevisal(@dataJos,@dataSus,'') a
			left outer join istpers i on i.Data=@dataSus and i.Marca=a.Marca
			left outer join personal p on p.Marca=a.Marca

	select c.Data, c.Marca, 
		sum((case when c.tip_concediu=1 then c.zile else 0 end)) as Zile_CFS, 
		sum((case when c.tip_concediu=2 and c.indemnizatie=0 then c.zile else 0 end)*rl.RL)+sum(case when c.tip_concediu=2 then indemnizatie else 0 end) as ore_nemotivate, 
		sum((case when c.tip_concediu=3 and c.indemnizatie=0 then c.zile else 0 end)*rl.RL)+sum(case when c.tip_concediu=3 then indemnizatie else 0 end) as ore_invoiri
	into #conalte
	from conalte c 
		left outer join fDate_pontaj_automat(@datajos, @datasus, @dataSus, 'RL', '', 0, 0) rl on rl.marca=c.marca
	where c.data between @dataJos and @dataSus and c.tip_concediu in ('1','2','3') 
	group by c.Data, c.Marca

--	corelatii date concedii medicale/concedii de odihna (zile macheta <-> ore pontaj)
	insert into #necorelatii
	select distinct 'NP', 'Pontaj' as tabela, 'Ore/Zile CM' as camp, dbo.eom(a.data) as data, a.marca as marca, a.marca as continut, 
		'Necorelatie ore (zile) CM pontaj <-> concedii!' as explicatii, a.Loc_de_munca as Loc_de_munca, 
		a.zile_cm as valoare_1, convert(decimal(10,2),isnull(cm.Zile_CM,0)) as valoare_2
	from #pontaj a
		left outer join (select Data, Marca, sum(zile_lucratoare) as Zile_CM 
			from conmed c where c.data between @dataJos and @dataSus and c.Tip_diagnostic<>'0-' group by c.Data, c.Marca) cm on dbo.eom(a.Data)=cm.Data and a.Marca=cm.Marca
	where a.zile_cm<>isnull(cm.Zile_CM,0)
	union all
	select distinct 'NP', 'Pontaj' as tabela, 'Ore/Zile CO' as camp, dbo.eom(a.data) as data, a.marca as marca, a.marca as continut, 
		'Necorelatie ore (zile) CO pontaj <-> concedii!' as explicatii, a.Loc_de_munca as Loc_de_munca, 
		a.zile_co as valoare_1, convert(decimal(10,2),isnull(co.Zile_CO,0)) as valoare_2
	from #pontaj a
		left outer join (select Data, Marca, sum((case when c.Tip_concediu='5' then -1 else 1 end)*zile_CO) as Zile_CO 
			from concodih c where c.data between @dataJos and @dataSus and c.tip_concediu in ('1','4','5','7','8') group by c.Data, c.Marca) co 
				on dbo.eom(a.Data)=co.Data and co.marca=a.marca
	where @MachetaCO=1 and a.zile_co<>isnull(co.Zile_CO,0)
	union all
	select distinct 'NP', 'Pontaj' as tabela, 'Ore/Zile CO evenimente' as camp, dbo.eom(a.data) as data, a.marca as marca, a.marca as continut, 
		'Necorelatie ore (zile) CO pontaj <-> concedii!' as explicatii, a.Loc_de_munca as Loc_de_munca, 
		a.zile_obligatii as valoare_1, convert(decimal(10,2),isnull(ev.Zile_obligatii,0)) as valoare_2
	from #pontaj a
		left outer join (select Data, Marca, sum(zile_CO) as Zile_obligatii
			from concodih c where c.data between @dataJos and @dataSus and c.tip_concediu in ('2','E') group by c.Data, c.Marca) ev 
				on dbo.eom(a.Data)=ev.Data and ev.marca=a.marca
	where @COEvenInMachetaCO=1 and a.Zile_obligatii<>isnull(ev.Zile_obligatii,0)
	union all
	select distinct 'NP', 'Pontaj' as tabela, 'Ore/Zile CFS' as camp, dbo.eom(a.data) as data, a.marca as marca, a.marca as continut, 
		'Necorelatie ore (zile) CFS pontaj <-> concedii\alte!' as explicatii, a.Loc_de_munca as Loc_de_munca, 
		a.zile_cfs as valoare_1, convert(decimal(10,2),isnull(ca.Zile_CFS,0)) as valoare_2
	from #pontaj a
		left outer join #conalte ca on a.Data=ca.Data and a.marca=ca.marca
	where @NCHand=1 and a.zile_cfs<>isnull(ca.Zile_CFS,0)
	union all
	select distinct 'NP', 'Pontaj' as tabela, 'Ore nemotivate' as camp, dbo.eom(a.data) as data, a.marca as marca, a.marca as continut, 
		'Necorelatie ore nemotivate pontaj <-> concedii\alte!' as explicatii, a.Loc_de_munca as Loc_de_munca, 
		a.ore_nemotivate as valoare_1, convert(decimal(10),isnull(ca.ore_nemotivate,0)) as valoare_2
	from #pontaj a
		left outer join #conalte ca on a.Data=ca.Data and a.marca=ca.marca
	where @NCHand=1 and a.ore_nemotivate<>isnull(ca.ore_nemotivate,0)
/*	union all
	select distinct 'NP', 'Pontaj' as tabela, 'Ore invoiri' as camp, dbo.eom(a.data) as data, a.marca as marca, a.marca as continut, 
		'Necorelatie ore invoiri pontaj <-> concedii\alte!' as explicatii, a.Loc_de_munca as Loc_de_munca, 
		a.ore_invoiri as valoare_1, convert(decimal(10),isnull(ca.ore_invoiri,0)) as valoare_2
	from #pontaj a
		left outer join #conalte ca on a.Data=ca.Data and a.marca=ca.marca
	where @NCHand=1 and a.ore_invoiri<>isnull(ca.ore_invoiri,0)*/
--	salariati nepontati
	union all 
	select 'SN', 'Pontaj', '' as camp, fc.Data_lunii as data, p.Marca, p.Marca as continut, 'Salariat nepontat' as explicatii, p.Loc_de_munca,
		0 as valoare_1, 0 as valoare_2
	from personal p
		left outer join fCalendar(@dataJos, @dataSus) fc on fc.Data=fc.Data_lunii
	where (convert(int,p.Loc_ramas_vacant)=0 or p.Data_plec>@dataJos)
		and p.Data_angajarii_in_unitate<=@dataSus
		and not exists (select 1 from pontaj po where po.Marca=p.Marca and po.Data between dbo.BOM(fc.Data_lunii) and fc.Data_lunii)
--	salariati pontati eronat (ore justificate din pontaj<>ore lucratoare salariat)
	union all 
	select 'PE', 'Pontaj', '' as camp, data, marca, marca as continut, 'Pontaj eronat (ore justificate<>ore lucratoare)', 
		lm, ore_justificate as valoare_1, ore_lucratoare as valoare_2
	from frapSalariatiPontatiEronat	(@datajos, @datasus, null, 0, null, null, null, null, 'T', 1)

	if exists (select 1 from sysobjects where [type]='P' and [name]='wIaVerificareDLSalariiSP1')
		exec wIaVerificareDLSalariiSP1 @sesiune, @parXML

--	returnare date
	select @rezultat=
	(select (case when Tip_validare='CE' then 'Coduri eronate' when Tip_validare='SI' then 'Date eronate pt. salariati inactivi' 
		when Tip_validare='DP' then 'Date personal de modificat' when Tip_validare='RV' then 'Date revisal' 
		when Tip_validare='NP' then 'Necorelatie pontaj-concedii' when Tip_validare='SN' then 'Salariati nepontati' 
		when Tip_validare='PE' then 'Pontati eronat' end) as validare, 
		rtrim(tabela) as tabela, rtrim(camp) as camp, rtrim(convert(char(10),data,101)) as data, rtrim(e.marca) as marca, rtrim(p.Nume) as densalariat, 
		rtrim(continut) as continut, rtrim(explicatii) as explicatii, convert(decimal(10,2),Valoare_1) as valoare1, convert(decimal(10,2),Valoare_2) as valoare2
	from #necorelatii e
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and e.Loc_de_munca=lu.cod
		left outer join personal p on p.Marca=e.Marca
		left outer join lm on lm.Cod=e.Loc_de_munca
	where (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)	
		and (@filtruMarca='' or e.Marca like @filtruMarca+'%' or p.Nume like '%'+replace(@filtruMarca,' ','%')+'%')
		and (@filtruLM='' or e.Loc_de_munca like @filtruLM+'%' or lm.Denumire like '%'+replace(@filtruLM,' ','%')+'%')
		and (@tipValidare='' or Tip_validare=@tipValidare or charindex(Tip_validare,@tipValidare)<>0)
		and (@filtruValidare='' 
			or (case when Tip_validare='CE' then 'Coduri eronate' when Tip_validare='SI' then 'Date eronate pt. salariati inactivi' 
				when Tip_validare='RV' then 'Date revisal' when Tip_validare='DP' then 'Date personal de modificat' 
				when Tip_validare='NP' then 'Necorelatie pontaj-concedii' when Tip_validare='SN' then 'Salariati nepontati' 
				when Tip_validare='PE' then 'Pontati eronat' end) like '%'+REPLACE(@filtruValidare,' ','%')+'%')
		and (@filtruExplicatii='' or e.Explicatii like '%'+replace(@filtruExplicatii,' ','%')+'%')
	order by Tip_validare, Data, Camp
	for xml raw )

	select @rezultat

end try

begin catch
	set @mesajeroare='wIaVerificareDLSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+ERROR_MESSAGE()
	raiserror(@mesajeroare, 16, 1)
end catch

IF OBJECT_ID('tempdb..#necorelatii') IS NOT NULL drop table #necorelatii
IF OBJECT_ID('tempdb..#personal') IS NOT NULL drop table #personal
IF OBJECT_ID('tempdb..#pontaj') IS NOT NULL drop table #pontaj
