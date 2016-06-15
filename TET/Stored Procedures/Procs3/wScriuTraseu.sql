--***

CREATE procedure  wScriuTraseu  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(50), @plecare varchar(50), @o_cod varchar(50), 
		@sosire varchar(50), @via varchar(50)  
		

set @cod= rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(50)'), ''))
set @o_cod= rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(50)'), ''))
set	@plecare = rtrim(isnull(@parXML.value('(/row/@plecare)[1]', 'varchar(50)'), ''))
set	@sosire= rtrim(isnull(@parXML.value('(/row/@sosire)[1]', 'varchar(50)'), ''))
set	@via = rtrim(isnull(@parXML.value('(/row/@via)[1]', 'varchar(50)'), ''))


--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update trasee  set Cod=@cod, Plecare=@plecare, Sosire=@sosire, Via=@via
		where Cod =@o_cod
	return
end

--Aici incepe partea de adaugare
if exists(select Cod from trasee where Cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Cod: '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	

else
	insert into trasee (Cod, Plecare, Sosire, Via)
	       VALUES (@cod, @plecare, @sosire, @via)
	       
       
