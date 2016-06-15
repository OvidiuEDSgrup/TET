--***
/****** Object:  StoredProcedure [dbo].[wUAValidareTipurideincasari]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAValidareTipurideincasari] 
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
	declare     @mesajeroare varchar(600),@id varchar(3),@o_id varchar(3),@denumire varchar(30), 
				@cont varchar(13),@update bit
	
	Select      @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
				@id =isnull(@parXML.value('(/row/@id)[1]','varchar(3)'),''),
				@denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),''),
				@cont= isnull(@parXML.value('(/row/@cont)[1]','varchar(13)'),''),
				@o_id= isnull(@parXML.value('(/row/@o_id)[1]','varchar(3)'),'')
	
	if @update=0 	
	
			if @id in (select id from tipuri_de_incasare)
	    begin
			set @mesajeroare='Id existent deja!'
			raiserror(@mesajeroare,11,1)
			return -1
		end
	
	
	if @update=1 				
			if @o_id in (select distinct(tip_incasare) from incasarifactabon) and @id<>@o_id
			begin
			set @mesajeroare='Id-ul nu se poate modifica ,exista incasari pe acest id!'
			raiserror(@mesajeroare,11,1)
			return -1
			end
  
    
    
	
	if @update=1 or @update=0  
    begin			
			
			
			if @denumire = ''
			begin
			set @mesajeroare='Introduceti denumirea!'
			raiserror(@mesajeroare,11,1)
			return -1
			end

			if @cont not in (select cont from conturi)
			begin
			set @mesajeroare='Cont inexistent!'
			raiserror(@mesajeroare,11,1)
			return -1
			end				
	      
			
	
	end		
	return 0		
	end
