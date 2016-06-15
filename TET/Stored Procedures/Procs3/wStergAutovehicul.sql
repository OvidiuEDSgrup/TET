﻿--***
create procedure wStergAutovehicul @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20), @mesajeroare varchar(254)

Set @cod = @parXML.value('(/row/@codautovehicul)[1]','varchar(20)')
set @mesajeroare=(case when exists (select 1 from devauto where Autovehicul=@cod) then 
	'Codul ales este folosit in documente sau in alte cataloage!' 
	when @cod is null then 'Nu a fost ales codul pt. stergere!' else '' end)

if @mesajeroare=''
	delete from auto where cod=@cod
else 
	raiserror(@mesajeroare, 11, 1)

end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
