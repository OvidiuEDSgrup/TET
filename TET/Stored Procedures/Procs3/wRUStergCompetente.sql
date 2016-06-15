--***
/* Procedura pt. stergere competente */
Create procedure wRUStergCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergCompetenteSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_competenta int, @mesajeroare varchar(500)      
begin try          
	select
		@id_competenta = isnull(@parXML.value('(/row/@id_competenta)[1]','int'),0)         

	delete from RU_competente where id_competenta=@id_competenta
end try

begin catch
	set @mesajeroare = '(wRUStergCompetente) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch