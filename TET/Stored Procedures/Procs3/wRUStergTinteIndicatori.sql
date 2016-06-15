--***
/** procedura pt. stergere tinte indicatori*/
Create procedure wRUStergTinteIndicatori @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergTinteIndicatoriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergTinteIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_tinta int, @mesajeroare varchar(500)      
begin try          
	select
		@id_tinta = isnull(@parXML.value('(/row/row/@id_tinta)[1]','int'),0)         
	
	delete from RU_tinte_indicatori where ID_tinta=@id_tinta
end try

begin catch
	set @mesajeroare = '(wRUStergTinteIndicatori) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
