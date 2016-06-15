/** Procedura pentru autocomplete nivele organigrama **/
--***
Create procedure wRUACNiveleOrganigrama @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACNiveleOrganigramaSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACNiveleOrganigramaSP @sesiune, @parXML output
	return @returnValue
end

declare @searchText varchar(80), @tip varchar(2), @utilizator char(10), @mesaj varchar(200)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

	set @searchText=REPLACE(@searchText, ' ', '%')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select n.ID_nivel as cod, rtrim(n.descriere) as denumire, 
	'Nivel ierarhic: '+CONVERT(varchar,n.nivel_organigrama) as info
	from RU_nivele_organigrama n
	where (n.ID_nivel like @searchText + '%' or n.Nivel_organigrama like  @searchText + '%'  or n.Descriere like  @searchText + '%')
	order by n.ID_nivel
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACNiveleOrganigrama)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
