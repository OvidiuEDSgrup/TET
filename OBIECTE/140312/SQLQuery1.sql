select rtrim(p.tert) as tert,
	rtrim(p.identificator) as identificator, rtrim(p.descriere) as descriere, 
	rtrim(isnull(p.loc_munca, '')) as info3, 
	rtrim(p.pers_contact) as nume, rtrim(p.nume_delegat) as prenume, 
	rtrim(dbo.fStrToken(p.buletin, 1, ',')) as seriebuletin, 
	rtrim(dbo.fStrToken(p.buletin, 2, ',')) as numarbuletin, 
	rtrim(dbo.fStrToken(p.Eliberat, 1, ',')) as eliberatbuletin,
	rtrim(dbo.fStrToken(p.Eliberat, 2, ',')) as nrmijtransp
	from infotert p where p.Subunitate like 'c%'