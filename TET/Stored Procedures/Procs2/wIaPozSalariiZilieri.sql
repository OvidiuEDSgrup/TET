--***
/*
	Procedura pt. selectie date la macheta de introducere salarii zilieri
*/
Create procedure wIaPozSalariiZilieri @sesiune varchar(50), @parXML xml
as  
Begin
	declare @datajos datetime, @datasus datetime, @data datetime, @lm varchar(9), @lmantet varchar(9), @cautare varchar(50)

	select @data=ISNULL(@parXML.value('(/row/@data)[1]','datetime'),''), 
		@lmantet=isnull(@parXML.value('(/row/@lmantet)[1]','varchar(9)'),''),
		@cautare=isnull(@parXML.value('(/row/@_cautare)[1]','varchar(9)'),'')
	select @datajos=dbo.Bom(@data), @datasus=dbo.Eom(@data)

	select 'SZ' as tip, 'Z' as subtip, 
	rtrim(convert(char(10),s.Data,101)) as data, RTRIM(s.Marca) as marca, RTRIM(Z.Nume) as denzilier,  
	Nr_curent as nrcrt, RTRIM(s.Loc_de_munca) as lm, rtrim (l.denumire) as denlm, 
	RTRIM(s.Comanda) as comanda, rtrim(c.descriere) as dencomanda, 
	RTRIM(s.Ora_inceput) as orainceput, RTRIM(s.Ora_sfarsit) as orasfarsit,
	convert(decimal(12,3),s.Salar_orar) as salor, s.Ore_lucrate as orelucrate, convert(decimal(12,3),s.Diferenta_salar) as difsal, 
	convert(decimal(12,0),s.Venit_total) as venittotal, convert(decimal(12,0),s.impozit) as impozit, convert(decimal(12,0),s.Rest_de_plata) as restplata, 
	RTRIM(s.Serie_registru) as serieregistru, RTRIM(s.Nr_registru) as nrreg, s.Pagina_registru as pagreg, s.Nr_curent_registru as nrcrreg, 
	RTRIM(s.Utilizator) as utilizator, s.Data_operarii as dataop, rtrim(s.Ora_operarii) as oraop, RTRIM(s.Explicatii) as explicatii
	from SalariiZilieri s
		left join Zilieri z on z.Marca=s.marca
		left join comenzi c on c.Comanda=s.comanda
		left join lm l on l.cod=s.loc_de_munca
	where s.Data between @datajos and @datasus and z.Loc_de_munca=@lmantet 
		and ((RTRIM(z.marca) like '%' + ISNULL(rtrim(@cautare),'') + '%') or (RTRIM(z.nume) like '%' + ISNULL(rtrim(@cautare),'')+'%') 
			or (RTRIM(s.Loc_de_munca) like '%' + ISNULL(rtrim(@cautare),'')+'%') or (RTRIM(l.denumire) like '%' + ISNULL(rtrim(@cautare),'')+'%') 
			or (RTRIM(convert(char(10),s.Data,101)) like '%' + ISNULL(rtrim(@cautare),'')+'%') 
			or (RTRIM(s.comanda) like '%' + ISNULL(rtrim(@cautare),'')+'%') or (RTRIM(c.descriere) like '%' + ISNULL(rtrim(@cautare),'')+'%'))
	for xml raw
end
