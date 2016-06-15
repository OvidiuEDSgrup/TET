--***
/****** Object:  StoredProcedure [dbo].[wRUStergObiectivePosturi]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergObiectivePosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_ob_posturi int,@mesajeroare varchar(500)    

begin try          
select
     @id_ob_posturi = isnull(@parXML.value('(/row/row/@ID_ob_posturi)[1]','int'),0)       

	delete from RU_obiective_posturi where ID_ob_posturi=@id_ob_posturi

end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
