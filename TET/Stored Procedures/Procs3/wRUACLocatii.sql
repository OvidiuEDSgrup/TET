/** obiect pt. autocomplete pe locatii instruiri **/
--***
Create procedure wRUACLocatii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACLocatiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACLocatiiSP @sesiune, @parXML output
	return @returnValue
end

declare @searchText varchar(80), @tip varchar(2), @mesaj varchar(200), @tiplocatie char(1)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@tiplocatie=ISNULL(@parXML.value('(/row/@tiplocatie)[1]', 'varchar(1)'), '')
	
	set @searchText=REPLACE(@searchText, ' ', '%')

	if @tiplocatie='T'
		exec wACTerti @sesiune, @parXML
	else
		exec wACLocm @sesiune, @parXML
		
end try

begin catch
	set @mesaj = '(wRUACLocatii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
