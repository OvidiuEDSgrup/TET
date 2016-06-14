     SELECT program_name FROM sys.dm_exec_sessions WHERE session_id=@@SPID
    SELECT *

    FROM sys.dm_exec_requests AS R

    CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS S

    WHERE session_id = @@SPID;
    
        SELECT *

    FROM sys.dm_exec_requests AS R

    CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS S

    WHERE session_id = @@SPID;
    
    SELECT * 
FROM sys.dm_exec_requests 
WHERE session_id = @@spid

    
    -- SQL log table
CREATE TABLE SQLLog (

 language_event NVARCHAR(100),

 parameters INT,

 event_info NVARCHAR(4000),

 event_time DATETIME DEFAULT CURRENT_TIMESTAMP);

 

-- Sample table to audit actions for

CREATE TABLE Foo (

 keycol INT PRIMARY KEY,

 datacol CHAR(1));

 

-- Sample data

INSERT INTO Foo VALUES (1, 'a');

INSERT INTO Foo VALUES (2, 'b');

INSERT INTO Foo VALUES (3, 'c');

 

GO

 

-- Audit trigger

CREATE TRIGGER LogMySQL

ON Foo

AFTER INSERT, UPDATE, DELETE

AS

 INSERT INTO SQLLog (language_event, parameters, event_info)

EXEC('DBCC INPUTBUFFER(@@SPID);');
    --INSERT INTO SQLLog (language_event, parameters, event_info)

    --EXEC('DBCC INPUTBUFFER(@@SPID);') AS LOGIN = 'admin_login';
GO

 

-- Perform some logged actions

GO

 

INSERT INTO Foo VALUES (4, 'd');

 

GO

 

DELETE Foo

WHERE keycol = 1;

 

GO

 

UPDATE Foo

SET datacol = 'f'

WHERE keycol = 2;

 

GO

 

-- Perform non-logged action

-- SELECT cannot be logged

SELECT datacol

FROM Foo

WHERE keycol = 4;

 

GO

 

-- Check what we have in the log

SELECT *

FROM SQLLog;

drop table SQLLog
drop table foo