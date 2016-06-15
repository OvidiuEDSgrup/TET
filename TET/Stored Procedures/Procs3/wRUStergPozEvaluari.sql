--***
/** procedura pt. stergere pozitii evaluari */
Create procedure wRUStergPozEvaluari @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergPozEvaluariSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergPozEvaluariSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @tip varchar(2), @id_evaluare int, @id_poz_evaluare int, @mesajeroare varchar(500)      
begin try          
	select @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@id_evaluare = isnull(@parXML.value('(/row/@id_evaluare)[1]','int'),0),
		@id_poz_evaluare = isnull(@parXML.value('(/row/row/@id_poz_evaluare)[1]','int'),0)
	
	delete from RU_poz_evaluari where ID_poz_evaluare=@id_poz_evaluare

	declare @docXMLIaPozEvaluari xml
	set @docXMLIaPozEvaluari ='<row id_evaluare="'+rtrim(convert(char(6),@id_evaluare))+'" tip="'+rtrim(convert(char(6),@tip))+'"/>'
	exec wRUIaPozEvaluari @sesiune=@sesiune, @parXML=@docXMLIaPozEvaluari
end try

begin catch
	set @mesajeroare = '(wRUStergPozEvaluari) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
