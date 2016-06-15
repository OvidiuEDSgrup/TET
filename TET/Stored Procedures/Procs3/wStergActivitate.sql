--***
create procedure [dbo].[wStergActivitate] @sesiune varchar(50), @parXML xml
as
begin try

declare @fisa varchar(20), @codMasina varchar(20), @tip varchar(20), @data datetime
Set @fisa= @parXML.value('(/row/row/@fisa)[1]','varchar(20)')
Set @codMasina= @parXML.value('(/row/@codMasina)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

if @mesajeroare=''	
	delete from activitati where Fisa=@fisa and Data=@data and tip=@tip 

else 
	raiserror(@mesajeroare, 11, 1)
	
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
