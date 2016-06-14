select * from sys.columns c inner join sys.objects o on o.object_id=c.object_id
where o.name='yso_vIaTargetag'
select * from INFORMATION_SCHEMA.COLUMNS c inner join INFORMATION_SCHEMA.VIEWS v on v.TABLE_NAME=c.TABLE_NAME
where v.TABLE_NAME='yso_vIaTargetag'