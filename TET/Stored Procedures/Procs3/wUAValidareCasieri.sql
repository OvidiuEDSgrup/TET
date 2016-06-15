--***
/****** Object:  StoredProcedure [dbo].[wUAValidareCasieri]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAValidareCasieri] 
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
	declare     @mesajeroare varchar(600),@codcasier varchar(10),@casier varchar(30),@update bit
	
	Select      @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
				@codcasier =isnull(@parXML.value('(/row/@codcasier)[1]','varchar(10)'),''),
				@casier =isnull(@parXML.value('(/row/@casier)[1]','varchar(30)'),'')
				
	
	if @update=0 	
	
			if @codcasier in (select cod_casier from casieri)
	    begin
			set @mesajeroare='Cod casier existent deja!'
			raiserror(@mesajeroare,11,1)
			return -1
		end
	
	

  
    if @update=1 or @update=0  
    begin			
			
			
			if @casier = ''
			begin
			set @mesajeroare='Introduceti nume casier!'
			raiserror(@mesajeroare,11,1)
			return -1
			end

		
	end		
	return 0		
	end
