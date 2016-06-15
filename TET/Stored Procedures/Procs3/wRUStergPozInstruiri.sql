--***
/** procedura pt. stergere pozitii instruiri */
Create procedure wRUStergPozInstruiri @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergPozInstruiriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergPozInstruiriSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @tip varchar(2), @id_instruire int, @id_poz_instruire int, @mesajeroare varchar(500)      
begin try          
	select @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@id_instruire = isnull(@parXML.value('(/row/@id_instruire)[1]','int'),0),
		@id_poz_instruire = isnull(@parXML.value('(/row/row/@id_poz_instruire)[1]','int'),0)
	
	delete from RU_poz_instruiri where ID_poz_instruire=@id_poz_instruire

	declare @docXMLIaPozInstruiri xml
	set @docXMLIaPozInstruiri ='<row id_instruire="'+rtrim(convert(char(6),@id_instruire))+'" tip="'+rtrim(convert(char(6),@tip))+'"/>'
	exec wRUIaPozInstruiri @sesiune=@sesiune, @parXML=@docXMLIaPozInstruiri
end try

begin catch
	set @mesajeroare = '(wRUStergPozInstruiri) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
