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
--facturi

GO

DECLARE csfact cursor for
select so.name as tabela,sc.name as coloana
--,TYPE_NAME(system_type_id) AS TIP,max_length, precision, scale,
 --,* 
 from sys.columns sc join sysobjects so on sc.object_id=so.id
where sc.name like '%fact%' and so.type='U' and sc.system_type_id IN (167,175) 
and sc.name not like '%data%'
and sc.name not like '%cont%'
and sc.name not like '%mod%'
and so.name not like '%IDX%'
and sc.name not like '%usc%'
and sc.MAX_length<25
order by 1,2

declare @tbl sysname,@col sysname, @sql varchar(1000)
OPEN csfact
fetch next from csfact into @tbl, @col
while @@FETCH_STATUS=0
begin
	SET @sql='ALTER TABLE '+LTRIM(RTRIM(QUOTENAME(@tbl)))+' ALTER COLUMN '+LTRIM(RTRIM(QUOTENAME(@col)))+' char(25) NOT NULL'
	print (@sql)
	EXEC (@SQL)
	fetch next from csfact into @tbl, @col
end
close csfact
deallocate csfact
