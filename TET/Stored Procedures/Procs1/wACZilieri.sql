--***
Create 
procedure wACZilieri @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACZilieriSP' and type='P')
	exec wACZilieriSP @sesiune, @parXML
else      
Begin
	declare @userASiS varchar(10), @iDoc int, @lmantet varchar(9)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	select @lmantet=@parXML.value('(/row/@lmantet)[1]','varchar(6)')

	select top 100 rtrim(z.Marca) as cod, rtrim(left(z.Nume,30)) as denumire
	from Zilieri z
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and z.Loc_de_munca=lu.cod
		, OPENXML(@iDoc, '/row')
	with (searchText varchar(80) '@searchText') filtre
	where (marca like replace(filtre.searchText,' ','%')+'%' 
		or nume like '%'+replace(filtre.searchText,' ','%')+'%') and (isnull(@lmantet,'')='' or @lmantet=z.Loc_de_munca)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by z.Marca
	for xml raw
End	
