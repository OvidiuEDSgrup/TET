/* procedura pt. autocomplete calificative */
--***
create procedure wRUACCalificative @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='proceduraModelSP')
begin 
	declare @returnValue int exec @returnValue = proceduraModelSP @sesiune, @parXML output
	return @returnValue
end

declare @codMeniu varchar(2), @an_evaluat int, @searchText varchar(80), @tip varchar(2), @mesaj varchar(200)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@codMeniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
		@an_evaluat=ISNULL(@parXML.value('(/row/@an_evaluat)[1]', 'int'), '') 	

	set @searchText=REPLACE(@searchText, ' ', '%')

	select c.ID_calificativ as cod, rtrim(c.Nivel_realizare) as denumire, RTRIM(c.Calificativ) as info
	from RU_calificative c
	where (c.ID_calificativ like @searchText + '%'  or c.Calificativ like '%' + @searchText + '%' or c.Nivel_realizare like '%' + @searchText + '%')
		and (@codMeniu<>'EV' or year(c.Data_sfarsit)=@an_evaluat)
	order by c.ID_calificativ
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACCalificative) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
