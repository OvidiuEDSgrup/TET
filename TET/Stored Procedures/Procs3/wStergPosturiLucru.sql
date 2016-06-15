--***
create procedure [dbo].[wStergPosturiLucru] @sesiune varchar(50), @parXML xml
as
begin try

declare @postlucru varchar(20)
Set @postlucru= @parXML.value('(/row/@postlucru)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''


if @mesajeroare=''
	delete from Posturi_de_lucru where Postul_de_lucru=@postlucru
else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
