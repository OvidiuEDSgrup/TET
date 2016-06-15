--***
Create procedure wRUStergEvaluari @sesiune varchar(50), @parXML xml 

as

Declare @mesajeroare varchar(100), @eroare xml 
begin try

	declare @iDoc int 
	exec sp_xml_preparedocument @iDoc output, @parXML  
	    
	select @mesajeroare= 
	(case 
	-- are pozitii
	when exists (select 1 from RU_poz_evaluari pe, OPENXML (@iDoc, '/row')  
	 WITH  
	 (  
	  tip varchar(2) '@tip',
	  id_evaluare int '@id_evaluare'
	 ) as ex  
	where pe.ID_evaluare=ex.id_evaluare) 
		then 'Documentul de evaluare are pozitii!'
	else '' end)

	if @mesajeroare<>'' 	
		raiserror(@mesajeroare, 11, 1)

	delete RU_evaluari from RU_evaluari e, OPENXML (@iDoc, '/row')  
	WITH  
	 (  
	  tip varchar(2) '@tip',
	  id_evaluare int '@id_evaluare'
	 ) as ex  
	where e.ID_evaluare=ex.id_evaluare and e.tip=ex.tip

end try
begin catch
	declare @mesaj varchar(255)
	set @mesaj = '(wRUStergEvaluari) '+ERROR_MESSAGE() 
	raiserror(@mesajeroare, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
