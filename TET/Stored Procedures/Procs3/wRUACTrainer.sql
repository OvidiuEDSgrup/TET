/** obiect pt. autocomplete pe trainer pe instruiri **/
--***
Create procedure wRUACTrainer @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACTrainerSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACTrainerSP @sesiune, @parXML output
	return @returnValue
end

declare @searchText varchar(80), @tip varchar(2), @mesaj varchar(200), @tiptrainer char(1)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@tiptrainer=ISNULL(@parXML.value('(/row/@tiptrainer)[1]', 'varchar(1)'), '')
	
	set @searchText=REPLACE(@searchText, ' ', '%')

	if @tiptrainer='F'
		exec wACTerti @sesiune, @parXML
	else
		exec wACSalariati @sesiune, @parXML
		
end try

begin catch
	set @mesaj = '(wRUACTrainer) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
