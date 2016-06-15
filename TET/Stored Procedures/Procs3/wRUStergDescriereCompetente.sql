/** procedura pentru stergere descriere competente **/
Create procedure wRUStergDescriereCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergDescriereCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergDescriereCompetenteSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_desc_comp int,@mesajeroare varchar(500)
begin try          
	select
		@id_desc_comp = isnull(@parXML.value('(/row/row/@id_desc_comp)[1]','int'),0)         

	delete from RU_descriere_competente where ID_desc_comp=@id_desc_comp
end try

begin catch
	set @mesajeroare = '(wRUStergDescriereCompetente) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch