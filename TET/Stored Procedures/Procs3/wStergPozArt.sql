--***
create procedure wStergPozArt @sesiune varchar(50), @parXML xml
as
begin try

declare @codresursa varchar(20), @tipresursa varchar(20)
Set @codresursa= @parXML.value('(row/row/@codresursa)[1]','varchar(20)')
Set @tipresursa= @parXML.value('(row/row/@tipresursa)[1]','varchar(20)')



declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''	
	delete from pozart where Cod_resursa=@codresursa --and tip_resursa=@tipresursa

else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
