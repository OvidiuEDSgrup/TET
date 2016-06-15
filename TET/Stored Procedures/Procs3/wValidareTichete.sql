--***
Create 
procedure wValidareTichete (@sesiune varchar(50), @document xml)
as 
begin
	declare @data datetime, @marca varchar(6), @lmantet varchar(9), @lmsal varchar(9),
	@Plecat int, @Data_plec datetime, @mesaj varchar(200)
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @marca=isnull(@document.value('(/row/row/@marca)[1]','varchar(6)'),'')
	set @lmantet=isnull(@document.value('(/row/@lmantet)[1]','varchar(9)'),'')
	select @lmsal=loc_de_munca, @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec 
	from personal where marca=@marca

	if @document.exist('/row/row')=1 and @marca not in (select marca from personal)
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @marca in (select marca from personal where loc_ramas_vacant=1 and Data_plec<dbo.bom(@data))
	begin
		set @mesaj='Salariatul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lmsal<>@lmantet
	begin
		raiserror('Salariatul apartine de alt loc de munca decat locul de munca selectat!',11,1)
		return -1
	end
end
