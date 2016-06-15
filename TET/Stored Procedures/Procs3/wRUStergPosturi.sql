--***
/****** Object:  StoredProcedure [dbo].[wRUStergPosturi]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergPosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_post int,@mesajeroare varchar(500)      

begin try          
select
     @id_post = isnull(@parXML.value('(/row/@ID_post)[1]','int'),0)         

	delete from RU_posturi where ID_post=@id_post

end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
