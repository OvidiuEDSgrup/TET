CREATE PROCEDURE dbo.Test2
AS
    CREATE TABLE #t(x INT PRIMARY KEY);
    INSERT INTO #t VALUES (2);
    SELECT Test2Col = x FROM #t;
    
    CREATE TABLE #tt(x INT PRIMARY KEY);
    INSERT INTO #tt VALUES (2);
    SELECT Test2Col = x FROM #tt;
    
    select * from #td
GO

CREATE PROCEDURE dbo.Test1
AS
    CREATE TABLE #t(x INT PRIMARY KEY);
    INSERT INTO #t VALUES (1);
    SELECT Test1Col = x FROM #t;
    
    CREATE TABLE #td(x INT PRIMARY KEY);
    INSERT INTO #td VALUES (1);
    SELECT Test1Col = x FROM #td;
EXEC Test2;
--select * from #tt
GO

CREATE TABLE #t(x INT PRIMARY KEY);
INSERT INTO #t VALUES (99);
GO

EXEC Test1;
GO
drop  PROCEDURE dbo.Test1
go
drop  PROCEDURE dbo.Test2
go
drop table #t
