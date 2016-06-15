--***
create procedure [dbo].[wACContracteBugetari] @sesiune varchar(50), @parXML XML
as

if exists(select * from sysobjects where name='wACContracteBugetariSP' and type='P')      
	exec wACContracteBugetariSP @sesiune, @parXML      
else      
begin
	declare @tip varchar(2), @searchText varchar(80), @tipContr varchar(2)

	select @searchText=replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ','%'),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
					
	
	select 'c|'+rtrim(c.contract) as cod, rtrim(t.Denumire)  as denumire	
	from con c 
		inner join terti t on t.Subunitate=c.Subunitate and t.Tert=c.Tert 
	where c.tip='FA' 
		and (rtrim(t.Denumire) like '%'+@searchText+'%' or RTRIM(t.Tert) like @searchText+'%' )
	
	union all
	
	select 't|'+rtrim(t.Tert) as cod,RTRIM(Denumire) as denumire 
	from terti t
	where t.tert not in (select t1.tert  from terti t1 inner join con c on c.Tert=t1.Tert)
		and (rtrim(t.Denumire) like '%'+@searchText+'%' or RTRIM(t.Tert) like @searchText+'%' )
	order by denumire
	for xml raw
end
