--***
/****** Object:  StoredProcedure [dbo].[wRUStergCompPosturi]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergCompPosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_comp_posturi int,@mesajeroare varchar(500)    

begin try          
select
     @id_comp_posturi = isnull(@parXML.value('(/row/row/@ID_comp_posturi)[1]','int'),0)       

	delete from RU_competente_posturi where ID_comp_posturi=@id_comp_posturi

end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
