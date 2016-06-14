CREATE PROC [dbo].[sp_who3] 
AS

    SET NOCOUNT ON 

    DECLARE @LoginName varchar(128)
    DECLARE @AppName varchar(128)

    SELECT [SPID] = s.[spid]
        , [CPU] = s.[cpu]
        , [Physical_IO] = s.[physical_io]
        , [Blocked] = s.[blocked]
        , [LoginName] = CONVERT([sysname], RTRIM(s.[Loginame]))
        , [Database] = d.[name]
        , [AppName] = s.[program_name]
        , [HostName] = s.[hostname]
        , [Status] = s.[Status]
        , [Cmd] = s.[cmd]
        , [Last Batch] = s.[last_batch]
        , [Kill Command] = 'Kill ' + CAST(s.[spid] AS varchar(10))
        , [Buffer Command] = 'DBCC InputBuffer(' + CAST(s.[spid] AS varchar(10)) 
                                                         + ')'
    FROM [master].[dbo].[sysprocesses] s WITH(NOLOCK)
    JOIN [master].[sys].[databases] d WITH(NOLOCK)
                ON s.[dbid] = d.[database_id]
    WHERE s.[Status]<>'background'
        AND s.[spid]<> @@SPID  --@CurrentSpid@
    ORDER BY s.[blocked] DESC, s.[physical_io] DESC, s.[cpu] DESC, CONVERT([sysname], RTRIM(s.[Loginame]))

    BEGIN
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

        SELECT [Spid] = er.[session_Id]
        , [ECID] = sp.[ECID]
        , [Database] = DB_NAME(sp.[dbid])
        , [User] = [nt_username]
        , [Status] = er.[status]
        , [Wait] = [wait_type]
        , [Individual Query] = SUBSTRING(qt.[text], er.[statement_start_offset] / 2, (CASE WHEN er.[statement_end_offset] = - 1 THEN LEN(CONVERT(VARCHAR(MAX), qt.[text])) * 2
                            ELSE er.[statement_end_offset] END - er.[statement_start_offset]) / 2)
        , [Parent Query] = qt.[text]
        , [Program] = sp.[program_name]
        , [Hostname] = sp.[Hostname]
        , [Domain] = sp.[nt_domain]
        , [Start_time] = er.[Start_time]
        FROM [sys].[dm_exec_requests] er WITH(NOLOCK)
        INNER JOIN [sys].[sysprocesses] sp WITH(NOLOCK)
                ON er.[session_id] = sp.[spid]
        CROSS APPLY [sys].[dm_exec_sql_text](er.[sql_handle]) qt 
        WHERE er.[session_Id] > 50                      -- Ignore system spids.
            AND er.[session_Id] NOT IN (@@SPID)     -- Ignore the current statement.
        ORDER BY er.[session_Id], sp.[ECID]
    END