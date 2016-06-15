--***
Create
procedure wACSalariati @sesiune varchar(50), @parXML XML  
as  
if exists(select * from sysobjects where name='wACSalariatiSP' and type='P')
	exec wACSalariatiSP @sesiune, @parXML
else      
Begin
	declare @userASiS varchar(10), @searchText varchar(100), @data datetime, @lmantet varchar(9),@faraRestrictiiProp int,@faraRestrictiiPlecat int, @cuSold int 
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
	set @faraRestrictiiProp=ISNULL(@parXML.value('(/row/@faraRestrictiiProp)[1]', 'int'), 0)
	set @faraRestrictiiPlecat=ISNULL(@parXML.value('(/row/@faraRestrictiiPlecat)[1]', 'int'), 0)
	set @cuSold=ISNULL(@parXML.value('(/row/@cuSold)[1]', 'int'), 0)
	
	select @data=xA.row.value('@data', 'datetime'), @lmantet=xA.row.value('@lmantet', 'varchar(9)')
	from @parXML.nodes('row') as xA(row)
  
	select top 100 rtrim(p.Marca) as cod, rtrim(p.Nume)+' ('+rtrim(f.Denumire)+')' as denumire, 
		(case when @cuSold=1 then 'Sold ' + CONVERT(varchar(20), convert(money, isnull((select SUM(d.sold) from deconturi d where d.marca=p.Marca),0)), 1) + ' lei' 
			else rtrim(p.Cod_numeric_personal) end)
		+' Lm. '+rtrim(p.Loc_de_munca) as info
	from personal p
	inner join functii f on f.Cod_functie=p.Cod_functie
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	where (p.Marca like @searchText+'%' or p.Nume like '%'+@searchText+'%' or f.Denumire like '%'+@searchText+'%')
		and (p.Loc_ramas_vacant=0 or (@data is null or p.Data_plec>dbo.Bom(@data)) or @faraRestrictiiPlecat=1)
		and (@lmantet is null or p.Loc_de_munca=@lmantet)
		and ((dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) or @faraRestrictiiProp=1)
	order by rtrim(p.Marca)  
	for xml raw
End
	
