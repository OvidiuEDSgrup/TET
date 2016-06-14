set transaction isolation level read uncommitted
webconfigtipuri
EXEC sp_MSForeachdb 'SELECT ''?'',o.name FROM [?].sys.sql_modules m inner join [?].sys.objects o on o.object_id=m.object_id 
where m.definition like ''%PozContracte%'' and o.type=''P'' and o.name not in (''wScriuPozContracte'',''wIaPozContracte'',''wStergPozContracte'')'
