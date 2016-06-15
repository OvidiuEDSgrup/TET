/** procedura pentru auto-complete cursuri **/
--***
Create procedure wRUACCursuri @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACCursuriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUACCursuriSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @lista_lm int, @searchText varchar(80), @tip varchar(2), @mesaj varchar(200)
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select c.ID_curs as cod, rtrim(c.Denumire) as denumire, rtrim(d.Denumire) as info
	from RU_cursuri c
		left outer join RU_domenii d on c.ID_domeniu=d.ID_domeniu
	where (c.ID_curs like @searchText + '%' or c.Denumire like '%' + @searchText + '%')
--	filtrez dupa Domeniu atasat locurilor de munca care s-au definit ca proprietate LOCMUNCA a utilizatorului
		and (@lista_lm=0 or c.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' 
		and Cod in (select Cod from LMFiltrare lu where lu.utilizator=@utilizator)))
	order by c.ID_curs
	for xml raw
end try
begin catch
	set @mesaj = '(wRUACCursuri) '+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	

