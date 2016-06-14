DECLARE @x xml
set @x=(select tert='RO12994590', '01/01/1921' as datajos for xml raw)
if object_id('tempdb..#docfacturi') is not null 
		drop table #docfacturi
	create table #docfacturi (ceva varchar(9))
exec CreazaDiezFacturi '#docfacturi'
exec pFacturi '', @x
select * from #docfacturi