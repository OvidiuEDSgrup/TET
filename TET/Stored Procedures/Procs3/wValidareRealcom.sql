--***
Create 
procedure wValidareRealcom (@sesiune varchar(50), @document xml)
as 
begin
	declare @sub varchar(9), @subtip varchar(2), @data datetime, @datadoc datetime, @marca varchar(6), @lm varchar(9), 
	@comanda varchar(20), @codreper varchar(20), @codoperatie varchar(20), @cantitate decimal(10,3), @lmantet varchar(9),
	@starecom char(1), @datainch datetime, @SalariiLm int, @nRealizari int, @ptupdate int
	set @sub=dbo.iauParA('GE','SUBPRO')
	set @nRealizari=dbo.iauParN('PS','REALIZARI')
	set @subtip=isnull(@document.value('(/row/row/@subtip)[1]','varchar(2)'),'')
	Set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	Set @datadoc=isnull(@document.value('(/row/row/@datadoc)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @lm=isnull(@document.value('(/row/row/@lm)[1]', 'varchar(9)'), isnull(@document.value('(/row/@lmantet)[1]', 'varchar(9)'), ''))
	set @comanda=isnull(@document.value('(/row/row/@comanda)[1]', 'varchar(20)'), '')
	set @codreper=isnull(@document.value('(/row/row/@codreper)[1]', 'varchar(20)'), '')
	set @codoperatie=isnull(@document.value('(/row/row/@codoperatie)[1]', 'varchar(20)'), '')
	set @cantitate=isnull(@document.value('(/row/row/@cantitate)[1]', 'decimal(10,3)'), '')
	set @lmantet=isnull(@document.value('(/row/@lmantet)[1]','varchar(9)'),'')
	set @ptupdate=isnull(@document.value('(/row/@update)[1]','int'),'')
	select @datainch=Data_inchiderii, @starecom=Starea_comenzii from comenzi where Subunitate=@sub and Comanda=@comanda
	select @SalariiLM=Salarii from strlm where Nivel=isnull((select Nivel from lm where cod=@lm),'')

	if @document.exist('/row/row')=1 and @marca not in (select marca from personal) and @subtip in ('AI')
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lm<>'' and @SalariiLm=0
	begin
		raiserror('Locul de munca nu este setat pentru SALARII!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lm not in (select cod from lm)
	begin
		raiserror('Loc de munca inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @comanda<>'' and @comanda not in (select comanda from comenzi where subunitate=@sub)
	begin
		raiserror('Comanda inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @ptupdate=0 and @starecom='I' and @Data>@datainch
	begin
		raiserror('Data documentului ulterioara datei inchiderii comenzii!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and dbo.eom(@datadoc)<>dbo.eom(@data)
	begin
		raiserror('Data documentului trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @nRealizari in (1,2) and @codreper<>'' and @codreper not in (select cod_tehn from tehn)
	begin
		raiserror('Cod produs inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @codoperatie<>'' and @codoperatie not in (select cod from catop)
	begin
		raiserror('Cod operatie inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @nRealizari in (1,2) 
	and @codreper<>'' and @codoperatie<>'' and @codoperatie not in (select cod from tehnpoz where tip='O' and cod_tehn=@codreper)
	begin
		raiserror('Pentru acest produs nu aveti definita aceasta operatie!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @cantitate=0
	begin
		raiserror('Cantitate nesemnificativa!',11,1)
		return -1
	end
end
