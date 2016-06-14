select * from sys.index_columns ic where ic.index_column_id<>ic.key_ordinal and ic.object_id=25819204
select * from sys.indexes i where i.object_id=25819204 and i.index_id=1
select * from sys.objects o where o.object_id=25819204

exec sp_help delegexp