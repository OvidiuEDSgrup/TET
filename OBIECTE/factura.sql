select so.name as tabela,sc.name as coloana,TYPE_NAME(system_type_id) AS TIP,max_length, precision, scale,
 * from sys.columns sc join sysobjects so on sc.object_id=so.id
where sc.name like '%fact%' and so.type='U' and sc.system_type_id IN (167,175) 
and sc.name not like '%data%'
and sc.name not like '%cont%'
and sc.name not like '%mod%'
and so.name not like '%IDX%'
and sc.name not like '%usc%'
and sc.MAX_length<25
order by 1,2

--SELECT * FROM SYSTYPES

IF OBJECT_ID ( 'dbo.doc_exy', 'U' ) IS NOT NULL 
    DROP TABLE dbo.doc_exy;
GO
-- Create a two-column table with a unique index on the varchar column.
CREATE TABLE dbo.doc_exy ( col_a varchar(5) UNIQUE NOT NULL, col_b decimal (4,2));
GO
INSERT INTO dbo.doc_exy VALUES ('Test', 99.99);
GO
-- Verify the current column size.
SELECT name, TYPE_NAME(system_type_id), max_length, precision, scale
FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.doc_exy');
GO
-- Increase the size of the varchar column.
ALTER TABLE dbo.doc_exy ALTER COLUMN col_a varchar(25);
GO
-- Increase the scale and precision of the decimal column.
ALTER TABLE dbo.doc_exy ALTER COLUMN col_b decimal (10,4);
GO
-- Insert a new row.
INSERT INTO dbo.doc_exy VALUES ('MyNewColumnSize', 99999.9999) ;
GO
-- Verify the current column size.
SELECT name, TYPE_NAME(system_type_id), max_length, precision, scale
FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.doc_exy');


GO

DECLARE csfactcol cursor for
select  so.name as tabela,sc.name as coloana, so.object_id, sc.column_id
--,TYPE_NAME(system_type_id) AS TIP,max_length, precision, scale,
 --,* 
 from [sys].[columns] sc join [sys].[objects] so on sc.object_id=so.object_id
where sc.name like '%fact%' and so.type='U' and sc.system_type_id IN (167,175) 
and sc.name not like '%data%'
and sc.name not like '%cont%'
and sc.name not like '%mod%'
and so.name not like '%IDX%'
and sc.name not like '%usc%'
and sc.MAX_length>20
order by 1,2

declare @tbl sysname,@col sysname, @sql varchar(1000), @objid int , @colid int, @idx sysname
OPEN csfactcol
fetch next from csfactcol into @tbl, @col, @objid, @colid
while @@FETCH_STATUS=0
begin
	DECLARE csfactidx cursor for
	select idx.name
	from [sys].[index_columns] ic join [sys].[indexes] idx on ic.index_id=idx.index_id
	where ic.object_id=@objid and ic.column_id=@colid
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
--FACTURI
go
--DROP INDEX [Unic] ON [dbo].[facturi] WITH ( ONLINE = OFF )
--ALTER TABLE facturi ALTER COLUMN factura char(20) NOT NULL

--select * from sys.index_columns
--exec sp_helptext [sys.indexes]
 	select 
 	so.name as tabela,sc.name as coloana, so.object_id, sc.column_id
 	,idx.name
	from [sys].[index_columns] ic inner join [sys].[indexes] idx on ic.object_id=idx.object_id and ic.index_id=idx.index_id
	inner JOIN [sys].[columns] sc ON ic.column_id=sc.column_id and sc.object_id=ic.object_id
	inner join [sys].[objects] so on ic.object_id=so.object_id 
	WHERE IC.object_id=1997302225
	
	SELECT * FROM SYS.objects ORDER BY NAME
	select * from sys.index_columns where object_id=1997302225
	
	_pozpv