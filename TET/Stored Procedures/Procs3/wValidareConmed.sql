--***
Create
procedure wValidareConmed (@sesiune varchar(50), @document xml)
as 
begin
	declare @marca varchar(6), @data datetime, @tipdiagnostic varchar(2), @datainceput datetime, @datasfarsit datetime,
	@cnpcopil varchar(13), @Plecat int, @Data_plec datetime, @eroare int, @mesaj varchar(200)
	set @eroare=0
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @tipdiagnostic=isnull(@document.value('(/row/row/@tipconcediu)[1]', 'varchar(2)'), '')
	set @datainceput=isnull(@document.value('(/row/row/@datainceput)[1]','datetime'),'')
	set @datasfarsit=isnull(@document.value('(/row/row/@datasfarsit)[1]','datetime'),'')
	set @cnpcopil=isnull(@document.value('(/row/row/@cnpcopil)[1]','varchar(13)'),'')
	select @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec from personal where marca=@marca
	if @tipdiagnostic='9-'
		exec wValidareCNP @cnpcopil, @eroare output, @mesaj output, '', ''

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
	if @document.exist('/row/row')=1 and @tipdiagnostic = ''
	begin
		raiserror('Tip diagnostic necompletat!',11,1)
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
	if @document.exist('/row/row')=1 and @tipdiagnostic<>'0-' and isnull(@document.value('(/row/row/@seriecm)[1]','varchar(2)'),'') = ''
	begin
		raiserror('Serie certificat medical necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipdiagnostic<>'0-' and isnull(@document.value('(/row/row/@numarcm)[1]', 'varchar(2)'), '') = ''
	begin
		raiserror('Numar certificat medical necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipdiagnostic='6-' and isnull(@document.value('(/row/row/@codurgenta)[1]', 'varchar(10)'), '') = ''
	begin
		raiserror('Cod urgenta necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipdiagnostic='5-' and isnull(@document.value('(/row/row/@codgrupaa)[1]', 'varchar(10)'), '') = ''
	begin
		raiserror('Cod grupa A necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipdiagnostic='9-' and @eroare<>0
	begin
		raiserror(@mesaj,11,1)
		return -1
	end
end
