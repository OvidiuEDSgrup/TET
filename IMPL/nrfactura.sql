
DECLARE csfactcol cursor for
select  so.name as tabela,sc.name as coloana, so.object_id, sc.column_id
--,TYPE_NAME(system_type_id) AS TIP,max_length, precision, scale,
 --,* 
 from [sys].[columns] sc inner join [sys].[objects] so on sc.object_id=so.object_id
where sc.name like '%fact%' and so.type='U' and sc.system_type_id IN (167,175) 
and sc.name not like '%data%'
and sc.name not like '%cont%'
and sc.name not like '%mod%'
and so.name not like '%IDX%'
and sc.name not like '%usc%'
and sc.MAX_length>20
order by 1,2

declare @tbl sysname,@col sysname, @sql varchar(1000), @objid int , @colid int, @idxid int, @idx sysname
OPEN csfactcol
fetch next from csfactcol into @tbl, @col, @objid, @colid
while @@FETCH_STATUS=0
begin
	DECLARE csfactidx cursor for
	select idx.name
	from [sys].[index_columns] ic inner join [sys].[indexes] idx on ic.object_id=idx.object_id and ic.index_id=idx.index_id
	where ic.object_id=@objid and ic.column_id=@colid --and ic.index_id=@idxid
	OPEN csfactidx 
	FETCH NEXT FROM csfactidx INTO @idx
	
	WHILE @@FETCH_STATUS=0
	BEGIN 
		DROP INDEX [Unic] ON [dbo].[facturi]
		SET @sql='DROP INDEX '+LTRIM(RTRIM(QUOTENAME(@idx)))+' ON '+LTRIM(RTRIM(QUOTENAME(@tbl)))
		print (@sql)
		EXEC (@SQL)
		FETCH NEXT FROM csfactidx INTO @idx
	END
	close csfactidx
	deallocate csfactidx
	
	SET @sql='ALTER TABLE '+LTRIM(RTRIM(QUOTENAME(@tbl)))+' ALTER COLUMN '+LTRIM(RTRIM(QUOTENAME(@col)))+' char(20) NOT NULL'
	print (@sql)
	EXEC (@SQL)
	fetch next from csfactcol into @tbl, @col, @objid, @colid
end
close csfactcol
deallocate csfactcol