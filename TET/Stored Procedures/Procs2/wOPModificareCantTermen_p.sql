--***
create procedure wOPModificareCantTermen_p @sesiune varchar(50), @parXML xml 
as  
begin try
declare @n_cantitate float,@update int,@mesaj varchar(500)

select 
	  @n_cantitate=ISNULL(@parXML.value('(/row/row/@Tcantitate)[1]', 'float'), ''),
	  @update=ISNULL(@parXML.value('(/row/@update)[1]', 'int'), '')

if @update=1
	return

select convert(decimal(17,5),@n_cantitate) n_cantitate
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
