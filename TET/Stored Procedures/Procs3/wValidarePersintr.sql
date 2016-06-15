--***
Create 
procedure wValidarePersintr (@sesiune varchar(50), @document xml)
as 
begin
	declare @luna int, @o_luna int, @an int, @o_an int, @data datetime, @o_data datetime, @marca varchar(6),
	@cnp varchar(13), @tipintr varchar(1), @nume varchar(50), @Data_angajarii datetime, @Plecat int, @Data_plec datetime, 
	@eroare int, @mesaj varchar(100), @LunaAngajarii char(15)
	set @luna=isnull(@document.value('(/row/row/@luna)[1]','int'),0) 
	set @o_luna=isnull(@document.value('(/row/row/@o_luna)[1]','int'),1)
	set @an=isnull(@document.value('(/row/row/@an)[1]','int'),0)
	set @o_an=isnull(@document.value('(/row/row/@o_an)[1]','int'),1901)
	set @data=dbo.Eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
	set @o_data=dbo.Eom(convert(datetime,str(@o_luna,2)+'/01/'+str(@o_an,4)))
	set @marca=isnull(@document.value('(/row/@marca)[1]','varchar(6)'),'')
	set @cnp=isnull(@document.value('(/row/row/@cnp)[1]','varchar(13)'),'')
	set @nume=isnull(@document.value('(/row/row/@nume)[1]','varchar(50)'),'')
	set @tipintr=isnull(@document.value('(/row/row/@tipintr)[1]','varchar(1)'),'')
	select @Data_angajarii=Data_angajarii_in_unitate, @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec 
	from personal where marca=@marca
	select @LunaAngajarii=LunaAlfa from fCalendar(@Data_angajarii,@Data_angajarii)
	exec wValidareCNP @cnp, @eroare output, @mesaj output, '', ''

	if @document.exist('/row/row')=1 and @marca not in (select marca from personal)
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @nume=''
	begin
		raiserror('Nume persoana in intretinere necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipintr=''
	begin
		raiserror('Tip intretinut necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @eroare<>0
	begin
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @luna=0
	begin
		raiserror('Luna necompletata!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @an=0
	begin
		raiserror('An necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Data_angajarii>dbo.eom(@data)
	begin
		set @mesaj='Salariatul selectat este angajat abia incepand cu data de '+convert(char(10),@Data_angajarii,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Plecat=1 and @Data_plec<dbo.bom(@data)
	begin
		set @mesaj='Salariatul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
end
