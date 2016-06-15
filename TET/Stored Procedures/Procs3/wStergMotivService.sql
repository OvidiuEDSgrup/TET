--***
create procedure wStergMotivService @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20), @mesajeroare varchar(254)

Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

set @mesajeroare=(case when exists (select 1 from programator where motiv_intrare=@cod) then 
	'Codul ales este folosit in documente sau in alte cataloage!' 
	when @cod is null then 'Nu a fost ales codul pt. stergere!' else '' end)

if @mesajeroare=''
	delete from mot_service where cod=@cod
else 
	raiserror(@mesajeroare, 11, 1)

end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
