
CREATE procedure wStergRapProductie @sesiune varchar(50), @parXML xml  
as
begin try
/** Procedura sterge un antet de realizari de tip Raport productie in cazul in care acesta nu are pozitii **/
	declare @id int, @mesaj varchar(max)
	
	set @id=@parXML.value('(/row/@idRealizare)[1]','int')
	
	if exists(select 1 from pozRealizari where idRealizare=@id)
	begin
		raiserror('Documentul are pozitii!',11,1)
		return 
	end	
	
	delete from Realizari where id=@id
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wStergRapProductie)'
	raiserror(@mesaj, 11,1)
end catch
