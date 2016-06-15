--***
create procedure wStergGrupaMasini @sesiune varchar(50), @parXML xml
as
begin try

declare @grupa varchar(20)
Set @grupa= @parXML.value('(/row/@grupa)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''


if @mesajeroare=''
	delete from grupemasini where grupa=@grupa
else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
