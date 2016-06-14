declare @tbname char(100)

create table #tbsize ([Name] sysname,Rows char(11),reserved varchar(18),Data varchar(18),index_size varchar(18),Unused varchar(18))
declare tmptb cursor for 
select --'['+rtrim(s.name)+']'+'.'+'['+rtrim(o.name)+']' 
rtrim(s.name)+'.'+ltrim(o.name) 
from sys.objects o join sys.schemas s on s.schema_id=o.schema_id where type='U'
open tmptb
fetch next from tmptb into @tbname
while @@fetch_status=0 
begin
	insert into #tbsize
	exec sp_spaceused @tbname

	fetch next from tmptb into @tbname
end
close tmptb
deallocate tmptb

select * 
from #tbsize
order by convert(bigint, left(reserved,len(reserved)-3)) desc

drop table #tbsize
