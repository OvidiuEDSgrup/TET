--***
/** Procedura pt. stergere date din organigrama functiilor  **/
Create procedure wRUStergOrganigrama @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergOrganigramaSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergOrganigramaSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_organigrama int, @mesajeroare varchar(500) 
begin try          
select
    @id_organigrama = isnull(@parXML.value('(/row/@id_organigrama)[1]','int'),0)       

	delete from RU_organigrama where ID_organigrama=@id_organigrama
end try

begin catch
	set @mesajeroare = '(wRUStergOrganigrama) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch