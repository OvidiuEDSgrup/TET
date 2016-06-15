--***
/****** Object:  StoredProcedure [dbo].[wRUStergIerarhiiPosturi]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergIerarhiiPosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_ierarhie_post int,@mesajeroare varchar(500)    

begin try          
select
     @id_ierarhie_post = isnull(@parXML.value('(/row/row/@ID_ierarhie_post)[1]','int'),0)       

	delete from RU_ierarhie_post where ID_ierarhie_post=@id_ierarhie_post

end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
