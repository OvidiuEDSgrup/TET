select OBJECT_NAME(c.object_id)
,* from sys.columns c where c.name like 'culoare'
--alter table pozcontracte add stare int