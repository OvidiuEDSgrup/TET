--***
Create 
procedure wValidareExtinfop (@sesiune varchar(50), @document xml)
as 
begin
	declare @data datetime, @data_veche datetime, @marca varchar(6), @cod varchar(20), @valoare varchar(80)

	set @data=isnull(@document.value('(/row/row/@data)[1]','datetime'),0) 
	set @data_veche=isnull(@document.value('(/row/row/@o_data)[1]','datetime'),0) 
	set @marca=isnull(@document.value('(/row/row/@marca)[1]','varchar(6)'),	isnull(@document.value('(/row/@marca)[1]','varchar(6)'),''))
	set @cod=isnull(@document.value('(/row/row/@cod)[1]','varchar(20)'),'')
	set @valoare=isnull(@document.value('(/row/row/@valoare)[1]','varchar(80)'),'')

	if @document.exist('/row/row')=1 and not exists (select marca from personal where Marca=@marca)
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @cod=''
	begin
		raiserror('Cod informatie necompletat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and not exists (select cod from catinfop where Cod=@cod)
	begin
		raiserror('Cod informatie inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and isnull((select Tip from catinfop where Cod=@cod),'')='V' and not exists (select Valoare from valinfopers where Cod_inf=@cod and Valoare=@valoare)
	begin
		raiserror('Valoare informatie nepermisa! Aceasta valoare nu este atasata codului de informatie selectat!',11,1)
		return -1
	end
end
