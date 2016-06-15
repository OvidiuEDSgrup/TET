--***
create procedure StergIndecsi @table varchar(1000)
as
DECLARE @indexName NVARCHAR(128)
DECLARE @dropIndexSql NVARCHAR(4000)


DECLARE tableIndexes CURSOR FOR
SELECT name FROM sysindexes
WHERE id = OBJECT_ID(@table) AND 
  indid > 0 AND indid < 255 AND
  INDEXPROPERTY(id, name, 'IsStatistics') = 0
ORDER BY indid DESC


OPEN tableIndexes
FETCH NEXT FROM tableIndexes INTO @indexName
WHILE @@fetch_status = 0
BEGIN
  SET @dropIndexSql = N'DROP INDEX '+@table+'.'+ @indexName
  EXEC sp_executesql @dropIndexSql

  FETCH NEXT FROM tableIndexes INTO @indexName
END


CLOSE tableIndexes
DEALLOCATE tableIndexes
