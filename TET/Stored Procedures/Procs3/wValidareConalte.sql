--***
Create 
procedure wValidareConalte (@sesiune varchar(50), @document xml)
as 
begin
	declare @RegimLV int, @marca varchar(6), @data datetime, @tipconcediu varchar(2), @datainceput datetime, @datasfarsit datetime, 
	@Ore int, @RegimLucru decimal (5,2), @Plecat int, @Data_plec datetime, @mesaj varchar(200)
	set @RegimLV=dbo.iauParL('PS','REGIMLV')
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @tipconcediu=isnull(@document.value('(/row/row/@tipconcediu)[1]', 'varchar(2)'),'')
	set @datainceput=isnull(@document.value('(/row/row/@datainceput)[1]','datetime'),'')
	set @datasfarsit=isnull(@document.value('(/row/row/@datasfarsit)[1]','datetime'),'')
	set @ore=isnull(@document.value('(/row/row/@ore)[1]', 'int'),'')
	select @RegimLucru=(case when @RegimLV=0 and Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end), 
	@Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec from personal where marca=@marca
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
	if @document.exist('/row/row')=1 and @tipconcediu = ''
	begin
		raiserror('Tip concediu necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and dbo.eom(@datainceput)<>dbo.eom(@data)
	begin
		raiserror('Data de inceput trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and dbo.eom(@datasfarsit)<>dbo.eom(@data)
	begin
		raiserror('Data de sfarsit trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @datasfarsit<@datainceput
	begin
		raiserror('Data de sfarsit este mai mica decat data inceput!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @ore<>0 and not(@tipconcediu='2' and @datainceput=@datasfarsit)
	begin
		raiserror('Campul ore se completeaza doar pt. tipul de concediu Nemotivate si daca data de inceput este egala cu data de sfarsit!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @ore<>0 and @ore>=@RegimLucru and @tipconcediu='2' and @datainceput=@datasfarsit
	begin
		raiserror('Campul ore trebuie sa fie mai mic decat regimul de lucru al salariatului!!',11,1)
		return -1
	end
end
