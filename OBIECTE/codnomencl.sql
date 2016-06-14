declare @tbl sysname,@col sysname, @sql varchar(1000), @objid int , @colid int, @idxid int, @idx sysname

DECLARE cscodcol cursor for
select t.Denumire_SQL,d.Camp_SQL, so.object_id, sc.column_id--, d.Conditie_de_inlocuire
from DetTabInl d join TabInl t on t.Tip=d.Tip and t.Numar_tabela=d.Numar_tabela
join [sys].[objects] so on so.name=t.Denumire_SQL 
join [sys].[columns] sc on sc.object_id=so.object_id and sc.name= d.Camp_SQL
where t.Tip=1 and so.type='U' and sc.system_type_id IN (167,175) and sc.MAX_length>20 and t.Inlocuiesc='da'
order by 1,2


OPEN cscodcol
fetch next from cscodcol into @tbl, @col, @objid, @colid
while @@FETCH_STATUS=0
begin
	DECLARE cscodidx cursor for
	select idx.name
	from [sys].[index_columns] ic inner join [sys].[indexes] idx on ic.object_id=idx.object_id and ic.index_id=idx.index_id
	where ic.object_id=@objid and ic.column_id=@colid --and ic.index_id=@idxid
	OPEN cscodidx 
	FETCH NEXT FROM cscodidx INTO @idx
	
	WHILE @@FETCH_STATUS=0
	BEGIN 
		SET @sql='DROP INDEX '+LTRIM(RTRIM(QUOTENAME(@idx)))+' ON '+LTRIM(RTRIM(QUOTENAME(@tbl)))
		print (@sql)
		EXEC (@SQL)
		FETCH NEXT FROM cscodidx INTO @idx
	END
	close cscodidx
	deallocate cscodidx
	
	SET @sql='ALTER TABLE '+LTRIM(RTRIM(QUOTENAME(@tbl)))+' ALTER COLUMN '+LTRIM(RTRIM(QUOTENAME(@col)))+' char(20) NOT NULL'
	print (@sql)
	EXEC (@SQL)
	fetch next from cscodcol into @tbl, @col, @objid, @colid
end
close cscodcol
deallocate cscodcol