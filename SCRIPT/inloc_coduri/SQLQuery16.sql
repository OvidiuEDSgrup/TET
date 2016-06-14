--pozdoc
select * from sys.objects o join sys.columns c  on c.object_id=o.object_id where o.name like 'pozdoc' 