--***
/****** Object:  StoredProcedure [dbo].[wRUStergOfunctii]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergFunctii] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_functie int       
begin try              
     select
         @id_functie = @parXML.value('(/row/@id_functie)[1]','int')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
delete from ru_functii where id_functie=@id_functie
end try
begin catch 
	raiserror(@mesajeroare, 11, 1)
end catch
