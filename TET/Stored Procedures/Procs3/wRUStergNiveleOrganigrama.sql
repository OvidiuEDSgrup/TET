--***
/** Procedura pt. stergere nivel organigrama **/
Create procedure wRUStergNiveleOrganigrama @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergNiveleOrganigramaSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergNiveleOrganigramaSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_nivel int,@mesajeroare varchar(500)    
begin try          
	select
		@id_nivel = isnull(@parXML.value('(/row/@id_nivel)[1]','int'),0)         

	delete from RU_nivele_organigrama where ID_nivel=@id_nivel
end try

begin catch
	set @mesajeroare = '(wRUStergNiveleOrganigrama) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch