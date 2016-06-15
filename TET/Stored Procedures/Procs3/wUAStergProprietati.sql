--***
/****** Object:  StoredProcedure [dbo].[wUAStergProprietati]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergProprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @cod varchar(20),@codproprietate varchar(20),@valoare varchar(200)       
        
     select
         @cod = @parXML.value('(/row/row/@cod)[1]','varchar(20)'),       
		 @codproprietate = @parXML.value('(/row/row/@codproprietate)[1]','varchar(20)'),
		 @valoare = @parXML.value('(/row/row/@valoare)[1]','varchar(200)')
		
		declare @catalog  varchar(1)
		set @catalog=(select catalog from catproprietati where cod_proprietate=@codproprietate)

declare @mesajeroare varchar(500)
set @mesajeroare=''


if @mesajeroare=''
	
	delete from proprietati where cod=@cod and cod_proprietate=@codproprietate and valoare=@valoare and tip=@catalog
else 
	raiserror(@mesajeroare, 11, 1)
