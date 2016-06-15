--***
create procedure [dbo].[wStergMasini] @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20)
Set @cod = @parXML.value('(/row/@codautovehicul)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''
	delete from auto where cod=@cod

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
