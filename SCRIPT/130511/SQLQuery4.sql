select c.* from sys.columns c inner join sys.objects o on o.object_id=c.object_id
inner join sys.types t on t.system_type_id=c.system_type_id
where o.name='pozincon'