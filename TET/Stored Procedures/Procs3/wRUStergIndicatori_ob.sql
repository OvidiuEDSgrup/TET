/** procedura pentru stergere indicatori pe obiective **/
Create PROCEDURE  wRUStergIndicatori_ob @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergIndicatori_obSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergIndicatori_obSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_ind_ob int, @mesajeroare varchar(500)      
begin try          
	select
		@id_ind_ob = isnull(@parXML.value('(/row/row/@id_ind_ob)[1]','int'),0)         

	delete from RU_indicatori_ob where id_ind_ob=@id_ind_ob
end try

begin catch
	set @mesajeroare = '(wRUStergIndicatori_ob) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch