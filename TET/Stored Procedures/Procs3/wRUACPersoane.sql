/** obiect pt. autocomplete pe catalogul de persoane **/
--***
Create procedure wRUACPersoane @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACPersoaneSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACPersoaneSP @sesiune, @parXML output
	return @returnValue
end

declare @searchText varchar(80), @tip varchar(2), @mesaj varchar(200)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

	set @searchText=REPLACE(@searchText, ' ', '%')

	select p.ID_pers as cod, rtrim(p.Nume) as denumire, RTRIM(p.Marca) as info
	from RU_persoane p
	where (p.ID_pers like @searchText + '%' or p.Nume like '%' + @searchText + '%')
	order by p.ID_pers
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACPersoane) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
