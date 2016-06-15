--***
/** procedura pentru stergere obiective pe functii **/
Create procedure wRUStergObiectiveFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergObiectiveFunctiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergObiectiveFunctiiSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_ob_functii int, @mesajeroare varchar(500)    
begin try          
select
    @id_ob_functii = isnull(@parXML.value('(/row/row/@id_ob_functii)[1]','int'),0)       

	delete from RU_obiective_functii where ID_ob_functii=@id_ob_functii
end try

begin catch
	set @mesajeroare = '(wRUStergObiectiveFunctii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch