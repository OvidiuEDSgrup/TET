--***
/** procedura pentru stergere profesii **/
Create procedure wRUStergProfesii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergProfesiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergProfesiiSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_profesie int,@mesajeroare varchar(500)       
begin try              
    select
        @id_profesie = @parXML.value('(/row/@id_profesie)[1]','int')         

	delete from ru_profesii where ID_profesie=@id_profesie
end try

begin catch
	set @mesajeroare = '(wRUStergProfesii) '+ERROR_MESSAGE()
end catch
if LEN(@mesajeroare)>0
	raiserror(@mesajeroare, 11, 1)