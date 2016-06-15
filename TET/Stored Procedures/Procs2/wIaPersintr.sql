--***
Create procedure wIaPersintr @sesiune varchar(50), @parXML xml
as  
Begin
	declare @marca char(6), @tip varchar(2), @data varchar(10), @datajos datetime, @datasus datetime, @userASiS varchar(10), 
	@LunaInch int, @AnulInch int, @DataInch datetime, @LunaImpl int, @AnulImpl int, @DataImpl datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	set @LunaInch=(case when dbo.iauParN('PS','LUNA-INCH')=0 then 1 else dbo.iauParN('PS','LUNA-INCH') end)
	set @AnulInch=(case when dbo.iauParN('PS','ANUL-INCH')=0 then 1901 else dbo.iauParN('PS','ANUL-INCH') end)
	set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))
	set @LunaImpl=(case when dbo.iauParN('PS','LUNAIMPL')=0 then 1 else dbo.iauParN('PS','LUNAIMPL') end)
	set @AnulImpl=(case when dbo.iauParN('PS','ANULIMPL')=0 then 1901 else dbo.iauParN('PS','ANULIMPL') end)
	set @DataImpl=dbo.Eom(convert(datetime,str(@LunaImpl,2)+'/01/'+str(@AnulImpl,4)))

	select @marca=xA.row.value('@marca', 'varchar(6)') from @parXML.nodes('row') as xA(row) 
	select @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
		@data=@parXML.value('(/row/@_cautare)[1]', 'varchar(10)')

	select @datajos=dbo.boy(Data_angajarii_in_unitate) from personal where marca=@marca
	select @datasus=dbo.eoy((select top 1 data from persintr where marca=@marca order by data desc))

	select (case when @tip='PN' then 'S' else @tip end) as tip, (case when @tip='S' then 'PN' else 'PI' end) as subtip, 'Persoane in intretinere' as densubtip, 
		convert(char(10),p.data,101) as data, 
		rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) as lunaan, rtrim(convert(char(2),month(p.Data))) as luna, year(p.Data) as an,
		'Persoane in intretinere' as denumire,
		rtrim(p.marca) as marca, rtrim(p.Nume_pren) as nume, rtrim(p.Cod_personal) as cnp,
		rtrim(p.Tip_intretinut) as tipintr, 
		(case p.Tip_intretinut when 'S' then 'Sot (sotie)' when 'C' then 'Primii 2  copii'
			when 'U' then 'Urmatorii copii' when 'A' then 'Altele' when 'E' then 'Elevi' when 'T' then 'Studenti' 
			when 'R' then 'Parinti pens.' when 'I' then 'Parinti nepens' when 'B' then 'Bunici' when 'D' then 'Somer' 
			when 'M' then 'Militar' when 'L' then 'Liber profesionisti' when 'P' then 'Pers cf Leg 416/2001' 
			when 'G' then 'Asig. cu venit agricol' when 'O' then 'Copii peste 18' else '' end) as dentipintr,
		rtrim(p.Grad_invalid) as gradinv, 
		(case p.Grad_invalid when '1' then 'Handicap grav' when '2' then 'Handicap accentuat' 
			when '3' then 'Handicap mediu' else 'Fara handicap' end) as dengradinv, 
		(case when convert(int,p.Coef_ded)=1 then 'Cu deducere' else 'Fara deducere' end) as tipded, 
		convert(int,p.Coef_ded) as coefded, convert(char(10),p.Data_nasterii,101) as datanasterii, 
		convert(char(10),e.Data_exp_ded,101) as dataexpded, convert(char(10),e.Data_exp_coasig,101) as dataexpcoasig, 
		convert(decimal(10),e.Venit_lunar) as venitlunar, convert(decimal(3,2),e.Deducere) as deducere,
		rtrim(e.Coasigurat) as coasigurat, rtrim(e.Tip_intretinut_2) as tipintr2, 
		convert(decimal(12,2),e.Valoare) as valoare, rtrim(e.Observatii) as observatii, 
		(case when p.Data<=@DataInch then '#808080' else '#000000' end) as culoare,
		(case when p.Data<=@DataInch then 1 else 0 end) as _nemodificabil
	from persintr as p
		left outer join extpersintr e on p.Data=e.Data and p.Marca=e.Marca and p.Cod_personal=e.Cod_personal
		inner join fCalendar (@datajos, @datasus) c on c.Data=p.Data 
	where p.Marca=@marca 
		and (@data is null 
			and (convert(char(10),p.Data,101) in (select top 1 convert(char(10),p1.Data,101) from persintr p1 where p1.Marca=@Marca order by p1.Data desc) or @tip='S1' and year(p.data)=year(getdate()))
				or convert(char(10),p.Data,103) like '%'+rtrim(@data)+'%' 
			or rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) like '%'+rtrim(@data)+'%')
	order by p.Data desc, p.Nume_pren
	for xml raw
End	
