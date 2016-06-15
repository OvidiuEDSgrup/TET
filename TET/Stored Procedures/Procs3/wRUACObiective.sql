/** procedura pentru auto-complete obiective **/
--***
Create procedure wRUACObiective @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACObiectiveSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUACObiectiveSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @searchText varchar(80), @tip varchar(2), @mesaj varchar(200), @codMeniu varchar(2), @id_evaluat int, @lm varchar(9), @an int, @categorie char(1)
begin try 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @searchText = ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@codMeniu = ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
		@id_evaluat = ISNULL(@parXML.value('(/row/@id_evaluat)[1]', 'int'), ''),
		@an = @parXML.value('(/row/@an)[1]', 'int'), 
		@categorie = ISNULL(@parXML.value('(/row/@categorie)[1]', 'varchar(1)'), '')
	select @lm=Loc_de_munca from RU_persoane where ID_pers=@id_evaluat	

	set @searchText=REPLACE(@searchText, ' ', '%')

	select c.ID_obiectiv as cod, rtrim(c.Denumire) as denumire, 
	'CATEG: '+(case when c.Categorie='1' then 'Companie' when c.Categorie='2' then 'Departament' when c.Categorie='3' then 'Individual' else '' end)+
	'. LM: '+rtrim(lm.Denumire) as info
	from RU_obiective c
		left outer join lm on lm.Cod=c.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and c.Loc_de_munca=lu.cod
	where (c.ID_obiectiv like @searchText + '%' or c.Denumire like '%' + @searchText + '%')
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
		and (@codMeniu<>'EV' or c.Loc_de_munca=@lm)
		and (@an is null or year(c.Data_sfarsit)=@an)
		and (@codMeniu<>'RO' or c.Categorie<>@categorie)
	order by c.ID_obiectiv
	for xml raw
end try

begin catch
	set @mesaj = '(wRUACObiective) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
