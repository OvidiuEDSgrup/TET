/****** Object:  StoredProcedure [dbo].[wUAValidarePreturi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAValidarePreturi] 
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
	declare     @mesajeroare varchar(600),@categorie int,@datainferioara datetime,
				@update bit,@cod varchar(20)
	
	Select      @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
				@categorie =isnull(@parXML.value('(/row/row/@categorie)[1]','int'),''),
				@datainferioara =isnull(@parXML.value('(/row/row/@datainferioara)[1]','datetime'),''),
                @cod =isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),'')

   	
	if @update=1 or @update=0  
    begin			
			
			if @categorie not in (select categorie from UACatpret)
			begin
			set @mesajeroare='Categorie pret inexistenta!'
			raiserror(@mesajeroare,11,1)
			return -1
			end				
	      
		    if @datainferioara < (select max(data_inferioara) from UApreturi where cod=@cod and categorie=@categorie)
			begin
			set @mesajeroare='Data inferioara incorecta!'
			raiserror(@mesajeroare,11,1)
			return -1
			end			
		
	if @update=0  
			
		   if @datainferioara = (select max(data_inferioara) from UApreturi where cod=@cod and categorie=@categorie)
			begin
			set @mesajeroare='Exista pozitie cu aceasta data inferioara incorecta, actualizati datele prin modificare!'
			raiserror(@mesajeroare,11,1)
			return -1
			end	
		
			
	end
	return 0		
	end
