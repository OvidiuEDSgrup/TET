--***
Create 
procedure wValidareResal (@sesiune varchar(50), @document xml)
as 
begin
	declare @data datetime, @marca varchar(6), @Plecat int, @Data_plec datetime, @codbenef varchar(13), @mesaj varchar(200)
	set @data=isnull(@document.value('(/row/row/@data)[1]','datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	select @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec from personal where marca=@marca
	set @codbenef=isnull(@document.value('(/row/row/@codbenef)[1]', 'varchar(13)'), @document.value('(/row/@codbenef)[1]', 'varchar(13)'))

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
	if @document.exist('/row/row')=1 and @codbenef = ''
	begin
		raiserror('Beneficiar retinere necompletat!',11,1)
		return -1
	end
end
