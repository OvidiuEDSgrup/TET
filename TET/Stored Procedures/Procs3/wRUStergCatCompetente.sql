--***
/****** Object:  StoredProcedure [dbo].[wRUStergCatCompetente]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergCatCompetente] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id_categ_comp int,@mesajeroare varchar(500)      

begin try          
select
     @id_categ_comp = @parXML.value('(/row/@ID_categ_comp)[1]','int')         

	delete from RU_categ_comp where ID_categ_comp=@id_categ_comp
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
