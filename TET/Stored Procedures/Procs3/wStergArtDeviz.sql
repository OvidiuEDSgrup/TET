--***
create procedure wStergArtDeviz @sesiune varchar(50), @parXML xml
as
begin try

declare @codarticol varchar(20)
Set @codarticol= @parXML.value('(row/@codarticol)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''	
	delete from art where Cod_articol=@codarticol

else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
