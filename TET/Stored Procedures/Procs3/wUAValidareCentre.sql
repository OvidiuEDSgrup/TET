--***
/****** Object:  StoredProcedure [dbo].[wUAValidareCentre]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAValidareCentre] 
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
	declare     @mesajeroare varchar(600),@centru varchar(8),@o_centru varchar(8),@dencentru varchar(30), 
				@localitate varchar(8),@lm varchar(9),@update bit
	
	Select      @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
				@centru =isnull(@parXML.value('(/row/@centru)[1]','varchar(8)'),''),
				@dencentru =isnull(@parXML.value('(/row/@dencentru)[1]','varchar(30)'),''),
				@localitate= isnull(@parXML.value('(/row/@localitate)[1]','varchar(8)'),''),
				@lm=isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
				@o_centru= isnull(@parXML.value('(/row/@o_centru)[1]','varchar(8)'),'')
	
	if @update=0 	
	
			if @centru in (select centru from centre)
	    begin
			set @mesajeroare='Centru exista deja!'
			raiserror(@mesajeroare,11,1)
			return -1
		end
	
	
	if @update=1 				
			if @o_centru in (select centru from abonati) and @centru<>@o_centru
			begin
			set @mesajeroare='Codul de centrul nu se poate modifica ,exista abonati pe acest centru!'
			raiserror(@mesajeroare,11,1)
			return -1
			end
    
    		if @centru in (select centru from centre) and @centru<>@o_centru
	    begin
			set @mesajeroare='Centru exista deja!'
			raiserror(@mesajeroare,11,1)
			return -1
		end
    
    
	
	if @update=1 or @update=0  
    begin			
			
			
			if @centru = ''
			begin
			set @mesajeroare='Introduceti codul de centru!'
			raiserror(@mesajeroare,11,1)
			return -1
			end
	
					
			if @dencentru = ''
			begin
			set @mesajeroare='Introduceti denumirea centrului!'
			raiserror(@mesajeroare,11,1)
			return -1
			end
	    
	   
			if @localitate not in (select cod_oras from localitati)
			begin
			set @mesajeroare='Oras inexistent!'
			raiserror(@mesajeroare,11,1)
			return -1
			end				
	      
	        if @lm not in (select cod from lm)
			begin
			set @mesajeroare='Loc de munca inexistent!'
			raiserror(@mesajeroare,11,1)
			return -1
			end	
			
	
	end		
	return 0		
	end
