--***
/****** Object:  StoredProcedure [dbo].[wRUStergDomeniiCompetente]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUStergDomeniiCompetente] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @ID_domeniu_comp int,@mesajeroare varchar(500)      

begin try          
select
     @ID_domeniu_comp = isnull(@parXML.value('(/row/@ID_domeniu_comp)[1]','int'),0)         

	delete from RU_domenii_competente where ID_domeniu_comp=@id_domeniu_comp

end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
