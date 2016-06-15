--***
Create
procedure wValidareSalariiZilieri (@sesiune varchar(50), @document xml)
as 
begin
	declare @sub varchar(9), @subtip varchar(2), @data datetime, @marca varchar(6), @lm varchar(9), @comanda varchar(20),
	@dataantet datetime, @lmantet varchar(9), @lmzil varchar(9), @Plecat int, @Data_plec datetime, 
	@mesaj varchar(200)
	set @sub=dbo.iauParA('GE','SUBPRO')
	set @subtip=isnull(@document.value('(/row/row/@subtip)[1]','varchar(2)'),'')
	Set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @lm=isnull(@document.value('(/row/row/@lm)[1]', 'varchar(9)'), '')
	set @comanda=isnull(@document.value('(/row/row/@comanda)[1]', 'varchar(20)'), '')
	set @dataantet=isnull(@document.value('(/row/@data)[1]', 'datetime'), '')
	set @lmantet=isnull(@document.value('(/row/@lmantet)[1]','varchar(9)'),'')
	select @lmzil=loc_de_munca, @Plecat=convert(int,Plecat), @Data_plec=Data_plecarii 
	from Zilieri where marca=@marca
	select @lm=@lmzil where @lm=''

	if @document.exist('/row/row')=1 and @data not between dbo.BOM(@dataantet) and dbo.EOM(@dataantet)
	begin
		raiserror('Data trebuie sa fie in luna de lucru!',11,1)
		return -1
	end

	if @document.exist('/row/row')=1 and @marca not in (select marca from Zilieri)
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Plecat=1 and @Data_plec<dbo.bom(@data)
	begin
		set @mesaj='Zilierul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lm not in (select cod from lm)
	begin
		raiserror('Loc de munca inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lmzil<>@lmantet and left(@subtip,1) in ('P','S')
	begin
		raiserror('Salariatul apartine de alt loc de munca decat locul de munca selectat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @comanda<>'' 
		and @comanda not in (select comanda from comenzi where subunitate=@sub)
	begin
		raiserror('Comanda inexistenta!',11,1)
		return -1
	end
end
