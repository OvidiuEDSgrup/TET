/** Procedura pentru stergere competente pe functii **/
Create procedure wRUStergCompetenteFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergCompetenteFunctiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergCompetenteFunctiiSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_comp_functii int, @mesajeroare varchar(500)      
begin try          
	select
		@id_comp_functii = isnull(@parXML.value('(/row/row/@id_comp_functii)[1]','int'),0)         

	delete from RU_competente_functii where ID_comp_functii=@id_comp_functii
end try

begin catch
	set @mesajeroare = '(wRUStergCompetenteFunctii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
