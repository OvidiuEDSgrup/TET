--***
create procedure wStergNomenclRes @sesiune varchar(50), @parXML xml
as
begin try

declare @codresursa varchar(20)
Set @codresursa= @parXML.value('(row/@codresursa)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''	
	delete from nomres where Cod_resursa=@codresursa

else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
