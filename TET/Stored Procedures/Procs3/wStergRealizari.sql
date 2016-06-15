
CREATE procedure wStergRealizari @sesiune varchar(50), @parXML xml  
as
begin try
	declare @id int,@mesaj varchar(max)
	
	set @id=@parXML.value('(/row/@idRealizare)[1]','int')
	
	if exists(select 1 from pozRealizari where idRealizare=@id)
	begin
		raiserror('Documentul are pozitii!',11,1)
	end	
	
	delete from Realizari where id=@id
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wStergRealizari)' 
	raiserror(@mesaj, 11,1)
end catch
