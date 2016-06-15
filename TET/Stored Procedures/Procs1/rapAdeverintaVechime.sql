/**
	Procedura este folosita pentru a lista Adeverinta de vechime. 
**/
create procedure rapAdeverintaVechime (@sesiune varchar(50), @marca varchar(6), @data datetime, @dataset char(2), @parXML xml='<row/>')
AS
/*
	exec rapAdeverintaVechime '', '81066', '06/01/2013', 'D', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF OBJECT_ID('tempdb..#adevvech') is not null drop table #adevvech
	IF OBJECT_ID('tempdb..##tmpadevvech') is not null drop table #tmpadevvech
	declare @datalunii datetime
	set @datalunii=dbo.eom(@data)

	select ROW_NUMBER() OVER(ORDER BY c.Datavig_act, c.Data_act) as nr_crt, c.Data_act, c.datavig_act as data_aplicare, 
	isnull(c.marca,p.marca) as marca, isnull(i.Nume,p.Nume) as nume, p.data_angajarii_in_unitate as data_angajarii, 
	(case when dbo.iauExtinfopVal(c.Marca,'CNTRITM')='' then ip.Nr_contract else dbo.iauExtinfopVal(c.Marca,'CNTRITM') end) as nr_contract,
	(case when dbo.iauExtinfopVal(c.Marca,'CNTRITM')='' then dbo.iauExtinfopData(c.Marca,'DATAINCH') else dbo.iauExtinfopData(c.Marca,'CNTRITM') end) as data_contract,
	dbo.iauExtinfopVal(c.Marca,'RTEMEIINCET') as temei_incetare,
	isnull(i.Cod_functie,p.Cod_functie) as cod_functie, f.Denumire as denumire_functie, isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza) as norma, 
	isnull(i.Salar_de_incadrare,(select top 1 Salar_de_incadrare from istpers i1 where i1.Marca=c.Marca order by data asc)) as salar_de_baza, 
	p.data_plec as data_plecarii, p.Copii as buletin, isnull(c.modificare,'') as explicatii, 
	dbo.iauExtinfopVal(c.Marca,'LOC_NASTERE') localitate_nastere, dbo.iauExtinfopVal(c.Marca,'JUD_NASTERE') as judet_nastere,
	convert(int,p.Loc_ramas_vacant) as plecat, rtrim(c.nr_act)+'/'+convert(char(10),c.Data_act,103) as nr_act
	into #tmpadevvech
	from dbo.fActeAditionale (@marca, @datalunii, @data, 1) c 
		left outer join personal p on c.marca=p.marca
		left outer join infopers ip on c.marca=ip.marca
		left outer join istpers i on dbo.eom(c.datavig_act)=i.data and c.marca=i.marca
		left outer join functii f on f.Cod_functie=isnull(i.Cod_functie,p.Cod_functie)
	order by p.Data_angajarii_in_unitate, c.marca, c.numar, c.datavig_act, c.data_act

	select nr_crt, data_act, data_aplicare, marca, nume, data_angajarii, nr_contract, data_contract, temei_incetare, cod_functie, denumire_functie, 
		norma, salar_de_baza, data_plecarii, buletin, explicatii, localitate_nastere, judet_nastere, nr_act
	into #adevvech 
	from #tmpadevvech

/*
	select cod_numeric_personal, max(cc.marci) as marci from personal p
	outer apply
	(select STUFF((select (marca)+', ' from personal where cod_numeric_personal=p.cod_numeric_personal
	for xml PATH(''),type).value('.','VARCHAR(MAX)'),1,0,''    ) as marci) cc
	where cod_numeric_personal='1480716054671'
	group by cod_numeric_personal
*/
--	update #adeverinta_vechime set Explicatii=rtrim(Explicatii)+char(10)+rtrim(@Explicatii) where Data_aplicare=@Data_aplicare and NrAct=@NrAct

	if exists (select 1 from #tmpadevvech where Plecat=1)
		insert into #adevvech
		select top 1 isnull(b.nr_crt,0)+1, data_plecarii, data_plecarii, marca, nume, data_angajarii, nr_contract, data_contract, temei_incetare, cod_functie, denumire_Functie, 
			norma, salar_de_baza, data_plecarii, buletin, 'INCETARE CIM', localitate_nastere, judet_nastere, 
			isnull((select top 1 rtrim(Val_inf)+'/'+convert(char(10),e1.Data_inf,103) from extinfop e1 where e1.Marca=a.Marca and e1.Cod_inf='AA' 
				and e1.Data_inf between DateAdd(month,-1,a.data_plecarii) and a.data_plecarii order by e1.Data_inf desc),convert(char(10),data_plecarii,103))
		from #tmpadevvech a
			outer apply (select top 1 nr_crt from #adevvech order by nr_crt desc) b
		order by a.nr_crt desc

	select nr_crt, data_act, data_aplicare, marca, nume, data_angajarii, nr_contract, data_contract, temei_incetare, cod_functie, denumire_functie, norma, salar_de_baza, data_plecarii, 
		buletin, explicatii, localitate_nastere, judet_nastere, nr_act,
		convert(char(4),year(data_aplicare)) as an, convert(char(2),month(data_aplicare)) as luna, convert(char(2),day(data_aplicare)) as ziua,
		rtrim(denumire_functie)+' - '+cast(norma as varchar(4))+' ore/zi' as functia
	from #adevvech
	order by nr_crt

end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE()+ ' (rapAdeverintaVechime)'
	raiserror(@mesaj, 11, 1)
end catch

