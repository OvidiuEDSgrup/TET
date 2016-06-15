/** procedura pentru auto-complete descriere competente **/
--***
Create procedure wRUACDescriereCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACDescriereCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUACDescriereCompetenteSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @lista_lm int, @searchText varchar(80), @tip varchar(2), @id_competenta int, @mesaj varchar(200)

begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@id_competenta=@parXML.value('(/row/@id_competenta)[1]', 'int')
	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select dc.ID_desc_comp as cod, rtrim(dc.Componenta) as denumire, 
		rtrim(c.Denumire) as info
	from RU_descriere_competente dc
		left outer join RU_competente c on c.ID_competenta=dc.ID_competenta
	where (dc.ID_desc_comp like @searchText + '%' or dc.Componenta like '%' + @searchText + '%' or dc.Descriere like '%' + @searchText + '%')
		and (@id_competenta is null or c.ID_competenta=@id_competenta)
	order by dc.ID_desc_comp
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACDescriereCompetente) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
