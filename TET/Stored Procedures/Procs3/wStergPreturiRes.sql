--***
create procedure wStergPreturiRes @sesiune varchar(50), @parXML xml
as
begin try

declare @tert varchar(20) ,@codresursa varchar(20), @tipresursa varchar(1)
Set @codresursa= @parXML.value('(row/@codresursa)[1]','varchar(20)')
Set @tipresursa= @parXML.value('(row/@tipresursa)[1]','varchar(20)')
Set @tert= @parXML.value('(row/row/@tert)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''	
	delete from ppreturi where Tert=@tert and Cod_resursa=@codresursa and tip_resursa=@tipresursa

else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
