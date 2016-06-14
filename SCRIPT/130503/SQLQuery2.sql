select p.rows,i.*,d.* from yso_DetTabInl d 
cross apply (select top 1 idindex=i.index_id, idobject=i.object_id, i.name
				from sys.index_columns ic 
					inner join sys.columns c on c.object_id=ic.object_id and c.column_id=ic.column_id
					inner join sys.indexes i on i.object_id=ic.object_id and i.index_id=ic.index_id 
					inner join sys.objects o on o.object_id=c.object_id
				where i.is_unique=1 and o.name=d.Camp_Magic and c.name=d.Camp_SQL order by i.index_id) i   
inner join sys.partitions p on p.object_id=i.idobject and p.index_id=i.idindex
where d.Tip=-2 and i.idindex<>0
order by p.rows desc
--select top 100 * from pozincon p 
--select * from contcor
--select * from tehnpoz

