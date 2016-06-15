
CREATE procedure wStergContacte @sesiune varchar(50), @parXML xml  
as 
begin try
	declare 
		@idContact int, @mesaj varchar(max)

	select
		@idContact=@parXML.value('(/*/@idContact)[1]','int')

	delete from Contacte where idContact=@idContact

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
