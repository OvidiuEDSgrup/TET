--***
/** procedura pentru stergere indicatori **/
Create procedure wRUStergIndicatori @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergIndicatoriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_indicator int, @mesajeroare varchar(500)  
begin try          
	select
		@id_indicator = isnull(@parXML.value('(/row/@id_indicator)[1]','int'),0)         

	delete from RU_indicatori where ID_indicator=@id_indicator

end try

begin catch
	set @mesajeroare = '(wRUStergIndicatori) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch