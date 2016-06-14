select o.name,*
from [sys.indexes] s inner join sys.objects o on o.object_id=s.object_id 
where s.is_unique=1 and s.type=2 and o.name='consdet'
--group by o.name having COUNT(*)>1
--consdet
select * from sys.index_columns