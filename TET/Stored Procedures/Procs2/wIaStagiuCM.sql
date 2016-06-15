--***
Create procedure wIaStagiuCM @sesiune varchar(50), @parXML xml
as  
Begin
	declare @cautare varchar(10), @marca char(6), @tip varchar(2), @datajos datetime, @datasus datetime, @userASiS varchar(10), 
	@LunaInch int, @AnulInch int, @DataInch datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	set @LunaInch=(case when dbo.iauParN('PS','LUNA-INCH')=0 then 1 else dbo.iauParN('PS','LUNA-INCH') end)
	set @AnulInch=(case when dbo.iauParN('PS','ANUL-INCH')=0 then 1901 else dbo.iauParN('PS','ANUL-INCH') end)
	set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

	select @marca=xA.row.value('@marca', 'varchar(6)') from @parXML.nodes('row') as xA(row) 
	select	@tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@cautare=@parXML.value('(/row/@_cautare)[1]', 'varchar(10)')

	select @datajos=isnull((select top 1 dbo.bom(data) from net where marca=@marca and day(data)=15 order by data asc),dbo.boy(DateAdd(year,-1,Data_angajarii_in_unitate))), 
		@datasus=isnull((select top 1 dbo.eom(data) from net where marca=@marca and day(data)=15 order by data desc),dbo.eoy(Data_angajarii_in_unitate))
	from personal where marca=@marca

	select @tip as tip, 'SM' as subtip, 'Stagiu concedii medicale' as densubtip, convert(char(10),n.data,101) as data, 
		rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) as lunaan, month(n.Data) as luna, year(n.Data) as an, 'Stagiu concedii medicale' as denumire,
		rtrim(n.marca) as marca, rtrim(p.Loc_de_munca) as lm, rtrim(lm.Denumire) as denlm, 
		convert(int,n.Ded_suplim) as zilestagiu, convert(int,n.Baza_CAS) as bazastagiu
	from net as n
		left outer join personal p on p.Marca=n.Marca 
		left outer join lm lm on lm.Cod=n.Loc_de_munca
		inner join fCalendar (@datajos, @datasus) c on c.Data=n.Data 
	where n.Marca=@marca and day(n.Data)=15
		and (@cautare is null or convert(char(10),n.Data,103) like '%'+rtrim(@cautare)+'%' 
		or rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) like '%'+rtrim(@cautare)+'%')
	order by n.Data desc
	for xml raw
End	
