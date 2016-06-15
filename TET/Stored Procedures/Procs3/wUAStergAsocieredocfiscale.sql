/****** Object:  StoredProcedure [dbo].[wUAStergAsocieredocfiscale]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAStergAsocieredocfiscale] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @codcasier varchar(20) ,@id int      
        
     select
        @codcasier=isnull(@parXML.value('(/row/@codcasier)[1]', 'varchar(20)'), ''),
		@id=isnull(@parXML.value('(/row/row/@id)[1]', 'int'), '')       

 delete from asocieredocfiscale where id=@id and cod=@codcasier
