/** procedura pentru auto-complete tipuri competente **/
--***
Create procedure wRUACTipCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACTipCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUACTipCompetenteSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @lista_lm int, @searchText varchar(80), @tip varchar(2), @id_competenta_parinte int, @mesaj varchar(200)
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@id_competenta_parinte=@parXML.value('(/row/@id_competenta_parinte)[1]', 'int')
	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select @id_competenta_parinte
	select '1' as cod, 'TEHNICA' as denumire, 'Tip competenta' as info 
	where @id_competenta_parinte=0
	union all 
	select '2' as cod, 'MANAGERIALA' as denumire, 'Tip competenta' as info
	where @id_competenta_parinte=0
	union all
	select '3' as cod, 'GENERALA' as denumire, 'Tip competenta' as info
	where @id_competenta_parinte=0
	union all
	select '6' as cod, 'CUNOSTINTE' as denumire, 'Tip componenta' as info
	where @id_competenta_parinte<>0
	union all
	select '7' as cod, 'ABILITATI' as denumire, 'Tip componenta' as info
	where @id_competenta_parinte<>0
	union all
	select '8' as cod, 'COMPORTAMENTE' as denumire, 'Tip componenta' as info
	where @id_competenta_parinte<>0
	order by cod
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACTipCompetente) '+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
