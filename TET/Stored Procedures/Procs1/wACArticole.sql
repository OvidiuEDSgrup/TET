--***
create procedure wACArticole @sesiune varchar(50), @parXML XML
as

if exists(select * from sysobjects where name='wACArticoleSP' and type='P')      
	exec wACArticoleSP @sesiune,@parXML      
else      
begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	select top 100 rtrim(Articol_de_calculatie) as cod, rtrim(denumire) as denumire
	from artcalc
	where (Articol_de_calculatie like @searchText+'%' 
		or denumire like '%'+@searchText+'%')
	order by rtrim(Articol_de_calculatie)
	for xml raw
end
