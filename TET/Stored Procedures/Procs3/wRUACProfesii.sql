/** procedura pentru auto-complete pe catalogul RU_profesii **/
--***
Create procedure wRUACProfesii @sesiune varchar(50), @parXML xml
As
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACProfesiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACProfesiiSP @sesiune, @parXML output
	return @returnValue
end

declare @searchText varchar(80),@tip varchar(2),@mesaj varchar(200)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

	set @searchText=REPLACE(@searchText, ' ', '%')

	select c.ID_profesie as cod, rtrim(c.Denumire) as denumire,RTRIM(c.Descriere) as info
	from RU_profesii c
	where (c.ID_profesie like @searchText + '%' or c.Denumire like '%' + @searchText + '%' or c.Descriere like '%' + @searchText + '%')
	order by c.ID_profesie
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACProfesii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
