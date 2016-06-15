--***
create procedure wStergCoefAm @sesiune varchar(50), @parXML xml
as
begin try

declare @dur float
Set @dur = @parXML.value('(/row/@dur)[1]','float')

declare @mesajeroare varchar(500)
set @mesajeroare=''

select @mesajeroare=
  (case	when @dur is null then 'Nu a fost ales articolul pt. stergere!'
		else '' end)

if @mesajeroare=''
	delete from coefMF where Dur=@dur
else 
	raiserror(@mesajeroare, 11, 1)
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
