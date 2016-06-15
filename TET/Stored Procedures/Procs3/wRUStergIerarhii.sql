--***
/****** Object:  StoredProcedure [dbo].[wRUStergIerarhii]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergIerarhii] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_ierarhie int,@mesajeroare varchar(500)      

begin try          
select
     @id_ierarhie = isnull(@parXML.value('(/row/@ID_ierarhie)[1]','int'),0)         

	delete from RU_ierarhii where ID_ierarhie=@id_ierarhie

end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
