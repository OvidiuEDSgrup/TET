--***
Create procedure wRUStergInstruiri @sesiune varchar(50), @parXML xml 

as

Declare @mesajeroare varchar(100), @eroare xml 
begin try

	declare @iDoc int 
	exec sp_xml_preparedocument @iDoc output, @parXML 
	    
	select @mesajeroare= 
	(case 
	-- are pozitii
	when exists 
		(select 1 from RU_poz_instruiri p, OPENXML (@iDoc, '/row')
			WITH (id_instruire int '@id_instruire') as ex
			where p.ID_instruire=ex.id_instruire)
		then 'Documentul de instruire are pozitii!'
	else '' end)

	if @mesajeroare<>''
		raiserror(@mesajeroare, 11, 1)

	delete RU_instruiri 
	from RU_instruiri i, OPENXML (@iDoc, '/row')  
		WITH (id_instruire int '@id_instruire') as ex
	where i.ID_instruire=ex.id_instruire

end try
begin catch
	declare @mesaj varchar(255)
	set @mesaj = '(wRUStergInstruiri) '+ERROR_MESSAGE() 
	raiserror(@mesajeroare, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
