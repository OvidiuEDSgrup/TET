--*** functie care sa aduca datele salariatilor; se va utiliza la adeverinte in reporting
create function fDateSalariati 
	(@marca varchar(6), @datalunii datetime)
returns @datesal table 
	(marca varchar(6), nume varchar(50), cnp varchar(13), tip_act varchar(2), serie_bul varchar(2), nr_bul varchar(8), elib varchar(100), data_elib varchar(100), 
	data_angajarii datetime, plecat int, data_plec datetime, data_nasterii datetime, 
	adresa varchar(200), strada varchar(25), numar varchar(10), bloc varchar(10), scara varchar(10), apartament varchar(10), sector int, 
	localitate varchar(100), judet varchar(50), nr_contract varchar(50), data_contract datetime, den_functie varchar(50), den_lm varchar(50), temei_incetare varchar(200), 
	tip_contract varchar(100), mod_angajare varchar(30), profesia varchar(50), nivel_studii varchar(30), 
	vechime_ani int, vechime_luni int, vechime_zile int, vechime_studii_ani int, vechime_studii_luni int, vechime_studii_zile int)
as 
begin
	insert into @datesal 
	select p.marca, p.nume, p.cod_numeric_personal, 
		(case when upper(left(p.copii,2))='SX' or charindex('X',p.copii)<>0 then 'CI' else 'BI' end) as tip_act, left(p.copii,2) as serie_bul, ltrim(rtrim(substring(p.copii,3,8))) nr_bul, 
		isnull(', eliberat de '+rtrim(isnull(nullif(p.detalii.value('(/row/@elib)[1]','varchar(100)'),''),db.val_inf)) ,'') as elib,
		isnull(', la data de '+isnull(nullif(p.detalii.value('(/row/@dataelib)[1]','varchar(10)'),''),convert(char(10),db.data_inf,103)),'') as data_elib,
		p.data_angajarii_in_unitate as data_angajarii, convert(int,p.Loc_ramas_vacant) as plecat, p.data_plec, p.data_nasterii, 
		(case when p.strada<>'' then ' str. ' else '' end)+rtrim(p.strada)+(case when p.numar<>'' then ' nr. ' else '' end)+rtrim(p.numar)
			+(case when p.bloc<>'' then ' bl. ' else '' end)+rtrim(p.bloc)+(case when p.scara<>'' then ' sc: ' else '' end)+rtrim(p.scara) as adresa,
		p.Strada, p.Numar, p.Bloc, p.Scara, p.Apartament, rtrim(convert(char(10),p.Sector)) as sector, 
		p.Localitate, (case when p.judet<>'' then ' judetul ' else '' end)+rtrim(p.Judet)+(case when p.sector<>0 then ' sector '+rtrim(convert(char(10),p.Sector)) else '' end) as judet, 
		ip.Nr_contract, dc.Data_inf as data_contract, 
		rtrim(f.denumire)+' (COR: '+rtrim(cf.Val_inf)+')' as den_functie, rtrim(lm.denumire) as den_lm, rtrim(tl.Val_inf) as temei_incetare, 
		(case when p.Grupa_de_munca='C' then 'timp partial' else 'norma intreaga' end)+' de '+rtrim(convert(char(3),p.Salar_lunar_de_baza))+' ore/zi' as tip_contract,
		(case when p.Mod_angajare='D' then 'determinata' else 'nedeterminata' end) as mod_angajare, 
		p.profesia as profesia, f.Nivel_de_studii as nivel_studii, 
		convert(int,(case when year(p.vechime_totala)=1899 then 1900 else year(p.vechime_totala)+(case when month(p.vechime_totala)=12 then 1 else 0 end) end)-1900) as vechime_ani,
		convert(int,(case when month(p.vechime_totala)=12 then 0 else month(p.vechime_totala) end)) as vechime_luni,
		convert(int,day(p.vechime_totala)) as vechime_zile,
		convert(int,left(ip.Vechime_studii,2)) as vechime_studii_ani,
		convert(int,substring(ip.Vechime_studii,3,2)) as vechime_studii_luni,
		convert(int,substring(ip.Vechime_studii,5,2)) as vechime_studii_zile
	from personal p 
		left outer join infopers ip on ip.marca=p.marca
		left outer join functii f on f.cod_functie=p.cod_functie
		left outer join extinfop cf on cf.Marca=p.Cod_functie and cf.Cod_inf='#CODCOR'
		left outer join lm on lm.cod=p.Loc_de_munca
		left outer join extinfop dc on dc.marca=p.marca and dc.cod_inf='DATAINCH'
		left outer join extinfop tl on tl.marca=p.marca and tl.cod_inf='RTEMEIINCET' and tl.data_inf='01/01/1901'
		outer apply (select top 1 val_inf, data_inf from extinfop b where b.Marca=p.marca and b.cod_inf='ELIB' and b.Data_inf<=dbo.EOM(@datalunii) order by data_inf desc) db
	where (@marca is null or p.marca=@marca)

	return
end
