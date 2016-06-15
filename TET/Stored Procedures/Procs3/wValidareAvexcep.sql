--***
Create 
procedure wValidareAvexcep (@sesiune varchar(50), @document xml)
as 
begin
	declare @subtip varchar(2), @data datetime, @marca varchar(6), @lmantet varchar(9), @lmsal varchar(9),
	@Plecat int, @Data_plec datetime, @mesaj varchar(200)
	set @subtip=isnull(@document.value('(/row/row/@subtip)[1]','varchar(2)'),'')
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @lmantet=isnull(@document.value('(/row/@lmantet)[1]','varchar(9)'),'')
	select @lmsal=loc_de_munca, @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec 
	from personal where marca=@marca

	if @document.exist('/row/row')=1 and @marca not in (select marca from personal)
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Plecat=1 and @Data_plec<dbo.bom(@data)
	begin
		set @mesaj='Salariatul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lmsal<>@lmantet --and @subtip='A2'
	begin
		raiserror('Salariatul apartine de alt loc de munca decat locul de munca selectat!',11,1)
		return -1
	end
end
