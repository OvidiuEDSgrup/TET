/** procedura pentru stergere furnizori cursuri **/
Create procedure wRUStergFurnizoriCursuri @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergFurnizoriCursuriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergFurnizoriCursuriSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_furnizor_curs int, @mesajeroare varchar(500)      
begin try          
	select
		@id_furnizor_curs = isnull(@parXML.value('(/row/row/@id_furnizor_curs)[1]','int'),0)         

	delete from RU_furnizori_cursuri where ID_furnizor_curs=@id_furnizor_curs
end try

begin catch
	set @mesajeroare = '(wRUStergFurnizoriCursuri) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch