--***
/** procedura pentru stergere obiective **/
Create procedure wRUStergObiective @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergObiectiveSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergObiectiveSP @sesiune, @parXML output
	return @returnValue
end

declare @id_obiectiv int, @mesajeroare varchar(500)
begin try              
	select 
		@id_obiectiv = @parXML.value('(/row/@id_obiectiv)[1]','int')         
	delete from RU_obiective where ID_obiectiv=@id_obiectiv
end try

begin catch 
	set @mesajeroare = '(wRUStergObiective) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch