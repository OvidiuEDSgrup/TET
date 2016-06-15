
create procedure wStergRetetaCod @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@id int
	set @id=@parXML.value('(/*/*/@id)[1]','int')

	delete from pozTehnologii where id=@id and not exists (select 1 from pozTehnologii where idp=@id)

end try
begin catch
	declare @mesaj varchar(max)
	set @mesaj= ERROR_MESSAGE() + ' (wStergRetetaCod)'
	raiserror(@mesaj, 16,1)
end catch
