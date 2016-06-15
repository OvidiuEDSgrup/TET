--***
Create procedure wIaSoldCO @sesiune varchar(50), @parXML xml
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

	select @datajos=DateAdd(year,-2,@DataInch)
	select @datasus=dbo.eoy(@DataInch)

	select @tip as tip, 'SO' as subtip, 'Sold CO ani anteriori' as densubtip, convert(char(10),i.data,101) as data, 
		rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) as lunaan, year(i.Data) as an,	'Sold CO ani anteriori' as denumire,
		rtrim(i.marca) as marca, convert(int,i.Coef_invalid) as zilecoram
	from istPers as i
		inner join fCalendar (@datajos, @datasus) c on c.Data=i.Data 
	where i.Marca=@marca and i.Data between @datajos and @datasus and i.Data=dbo.EOY(i.Data) 
		and (@cautare is null or convert(char(10),i.Data,103) like '%'+rtrim(@cautare)+'%' 
		or rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) like '%'+rtrim(@cautare)+'%')
	order by i.Data desc
	for xml raw
End	
