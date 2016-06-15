/** procedura pentru auto-complete indicatori resurse umane **/
--***
Create procedure wRUACIndicatori @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACIndicatoriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @lista_lm int, @searchText varchar(80), @tip varchar(2), @mesaj varchar(200), @codMeniu varchar(2), @id_evaluat int

begin try 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') ,
		@codMeniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
		@id_evaluat=ISNULL(@parXML.value('(/row/@id_evaluat)[1]', 'int'), '')

	set @searchText=REPLACE(@searchText, ' ', '%')

	select i.ID_indicator as cod, rtrim(i.Denumire) as denumire, 'Domeniu: '+RTRIM(d.Denumire) as info
	from RU_indicatori i
		left outer join RU_domenii d on i.ID_domeniu=d.ID_domeniu
	where (i.ID_indicator like @searchText + '%' or i.Denumire like '%' + @searchText + '%' )
		and (@lista_lm=0 or i.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' 
			and Cod in (select Cod from LMFiltrare lu where lu.utilizator=@utilizator)))
		and (@codMeniu<>'EV' or i.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' 
			and Cod in (select Loc_de_munca from RU_persoane p where p.ID_pers=@id_evaluat)))
	order by i.ID_indicator
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACIndicatori) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
