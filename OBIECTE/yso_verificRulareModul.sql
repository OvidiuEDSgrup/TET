drop procedure dbo.yso_verificRulareModul 
go
create procedure dbo.yso_verificRulareModul (@stringBeingSought NVARCHAR(MAX)=null, @isRunning bit=null output, @hostid varchar(20)=null output)    
as 
DECLARE @handle SMALLINT    -- the spid of the process
DECLARE @sql NVARCHAR(MAX)  -- the dynamic SQL
DECLARE @table TABLE ( EventType nvarchar(30) , [Parameters] int , EventInfo nvarchar(4000) )   -- the table variable holding the result of DBCC INPUTBUFFER execution
SET @isRunning = 0
SET @stringBeingSought = ISNULL(@stringBeingSought,'')
--select ASCII('a')

DECLARE procs CURSOR FOR SELECT session_id FROM sys.dm_exec_requests r 
WHERE status IN ('running', 'suspended', 'pending', 'runnable') and r.session_id<>@@SPID
ORDER BY session_id DESC  -- these are the processes to examine

OPEN procs
FETCH NEXT FROM procs INTO @handle
WHILE @@FETCH_STATUS=0
BEGIN          
    DELETE FROM @table

    SET @sql = 'DBCC INPUTBUFFER(' + CAST(@handle AS NVARCHAR) + ')'
           
    INSERT INTO @table
    EXEC (@sql) AS LOGIN='SA'

    SELECT @sql = EventInfo FROM @table
      
    IF CHARINDEX( @stringBeingSought, @sql, 0 ) > 0
    BEGIN
        SET @isRunning = 1
        select @handle,* from @table
    END
    FETCH NEXT FROM procs INTO @handle
END
CLOSE procs DEALLOCATE procs

set @isRunning=ISNULL(@isRunning, 0)