
select abs(t.rows-v.rows),* from 
(
select o.object_id,o.name,p.rows from test1.sys.objects o inner join test1.sys.partitions p on p.object_id=o.object_id and p.index_id=1
where o.type='u'
) t inner join
(
select o.object_id,o.name,p.rows from sys.objects o inner join sys.partitions p on p.object_id=o.object_id and p.index_id=1
where o.type='u'
) v on v.object_id=t.object_id
where t.rows<>v.rows
order by 1 desc