--/*
declare @trid int=(select top 1  id from sys.traces t where t.path like '%tracesp%')
if @trid is not null 
begin
	exec sp_trace_setstatus @trid,0
	exec sp_trace_setstatus @trid,2
end
go
exec master..xp_cmdshell N'del /q d:\EDS\SQL\TET\DEBUG\tracespuser.trc'
go
--*/
/****************************************************/
/* Created by: SQL Server 2008 R2 Profiler          */
/* Date: 08/23/2012  01:48:10 PM         */
/****************************************************/


-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 500

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 0, N'd:\EDS\SQL\TET\DEBUG\tracespuser', @maxfilesize, NULL 
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 162, 7, @on
exec sp_trace_setevent @TraceID, 162, 31, @on
exec sp_trace_setevent @TraceID, 162, 8, @on
exec sp_trace_setevent @TraceID, 162, 64, @on
exec sp_trace_setevent @TraceID, 162, 1, @on
exec sp_trace_setevent @TraceID, 162, 9, @on
exec sp_trace_setevent @TraceID, 162, 41, @on
exec sp_trace_setevent @TraceID, 162, 49, @on
exec sp_trace_setevent @TraceID, 162, 6, @on
exec sp_trace_setevent @TraceID, 162, 10, @on
exec sp_trace_setevent @TraceID, 162, 14, @on
exec sp_trace_setevent @TraceID, 162, 26, @on
exec sp_trace_setevent @TraceID, 162, 30, @on
exec sp_trace_setevent @TraceID, 162, 50, @on
exec sp_trace_setevent @TraceID, 162, 66, @on
exec sp_trace_setevent @TraceID, 162, 3, @on
exec sp_trace_setevent @TraceID, 162, 11, @on
exec sp_trace_setevent @TraceID, 162, 35, @on
exec sp_trace_setevent @TraceID, 162, 51, @on
exec sp_trace_setevent @TraceID, 162, 4, @on
exec sp_trace_setevent @TraceID, 162, 12, @on
exec sp_trace_setevent @TraceID, 162, 20, @on
exec sp_trace_setevent @TraceID, 162, 60, @on
exec sp_trace_setevent @TraceID, 14, 1, @on
exec sp_trace_setevent @TraceID, 14, 2, @on
exec sp_trace_setevent @TraceID, 14, 14, @on
exec sp_trace_setevent @TraceID, 14, 26, @on
exec sp_trace_setevent @TraceID, 14, 3, @on
exec sp_trace_setevent @TraceID, 14, 35, @on
exec sp_trace_setevent @TraceID, 14, 12, @on
exec sp_trace_setevent @TraceID, 15, 14, @on
exec sp_trace_setevent @TraceID, 15, 26, @on
exec sp_trace_setevent @TraceID, 15, 3, @on
exec sp_trace_setevent @TraceID, 15, 35, @on
exec sp_trace_setevent @TraceID, 15, 12, @on
exec sp_trace_setevent @TraceID, 17, 1, @on
exec sp_trace_setevent @TraceID, 17, 2, @on
exec sp_trace_setevent @TraceID, 17, 14, @on
exec sp_trace_setevent @TraceID, 17, 26, @on
exec sp_trace_setevent @TraceID, 17, 3, @on
exec sp_trace_setevent @TraceID, 17, 35, @on
exec sp_trace_setevent @TraceID, 17, 12, @on
exec sp_trace_setevent @TraceID, 10, 7, @on
exec sp_trace_setevent @TraceID, 10, 15, @on
exec sp_trace_setevent @TraceID, 10, 31, @on
exec sp_trace_setevent @TraceID, 10, 8, @on
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 48, @on
exec sp_trace_setevent @TraceID, 10, 64, @on
exec sp_trace_setevent @TraceID, 10, 1, @on
exec sp_trace_setevent @TraceID, 10, 9, @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 25, @on
exec sp_trace_setevent @TraceID, 10, 41, @on
exec sp_trace_setevent @TraceID, 10, 49, @on
exec sp_trace_setevent @TraceID, 10, 2, @on
exec sp_trace_setevent @TraceID, 10, 10, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 26, @on
exec sp_trace_setevent @TraceID, 10, 34, @on
exec sp_trace_setevent @TraceID, 10, 50, @on
exec sp_trace_setevent @TraceID, 10, 66, @on
exec sp_trace_setevent @TraceID, 10, 3, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 10, 51, @on
exec sp_trace_setevent @TraceID, 10, 4, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 60, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 6, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 43, 1, @on
exec sp_trace_setevent @TraceID, 43, 26, @on
exec sp_trace_setevent @TraceID, 43, 34, @on
exec sp_trace_setevent @TraceID, 43, 3, @on
exec sp_trace_setevent @TraceID, 43, 35, @on
exec sp_trace_setevent @TraceID, 43, 12, @on
exec sp_trace_setevent @TraceID, 43, 14, @on
exec sp_trace_setevent @TraceID, 43, 22, @on
exec sp_trace_setevent @TraceID, 45, 1, @on
exec sp_trace_setevent @TraceID, 45, 26, @on
exec sp_trace_setevent @TraceID, 45, 34, @on
exec sp_trace_setevent @TraceID, 45, 3, @on
exec sp_trace_setevent @TraceID, 45, 35, @on
exec sp_trace_setevent @TraceID, 45, 12, @on
exec sp_trace_setevent @TraceID, 45, 14, @on
exec sp_trace_setevent @TraceID, 45, 22, @on
exec sp_trace_setevent @TraceID, 12, 7, @on
exec sp_trace_setevent @TraceID, 12, 15, @on
exec sp_trace_setevent @TraceID, 12, 31, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 48, @on
exec sp_trace_setevent @TraceID, 12, 64, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 9, @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 41, @on
exec sp_trace_setevent @TraceID, 12, 49, @on
exec sp_trace_setevent @TraceID, 12, 6, @on
exec sp_trace_setevent @TraceID, 12, 10, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 26, @on
exec sp_trace_setevent @TraceID, 12, 50, @on
exec sp_trace_setevent @TraceID, 12, 66, @on
exec sp_trace_setevent @TraceID, 12, 3, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 51, @on
exec sp_trace_setevent @TraceID, 12, 4, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 60, @on
exec sp_trace_setevent @TraceID, 12, 13, @on
exec sp_trace_setevent @TraceID, 41, 7, @on
exec sp_trace_setevent @TraceID, 41, 15, @on
exec sp_trace_setevent @TraceID, 41, 55, @on
exec sp_trace_setevent @TraceID, 41, 8, @on
exec sp_trace_setevent @TraceID, 41, 16, @on
exec sp_trace_setevent @TraceID, 41, 48, @on
exec sp_trace_setevent @TraceID, 41, 64, @on
exec sp_trace_setevent @TraceID, 41, 1, @on
exec sp_trace_setevent @TraceID, 41, 9, @on
exec sp_trace_setevent @TraceID, 41, 17, @on
exec sp_trace_setevent @TraceID, 41, 25, @on
exec sp_trace_setevent @TraceID, 41, 41, @on
exec sp_trace_setevent @TraceID, 41, 49, @on
exec sp_trace_setevent @TraceID, 41, 10, @on
exec sp_trace_setevent @TraceID, 41, 18, @on
exec sp_trace_setevent @TraceID, 41, 26, @on
exec sp_trace_setevent @TraceID, 41, 50, @on
exec sp_trace_setevent @TraceID, 41, 66, @on
exec sp_trace_setevent @TraceID, 41, 3, @on
exec sp_trace_setevent @TraceID, 41, 11, @on
exec sp_trace_setevent @TraceID, 41, 35, @on
exec sp_trace_setevent @TraceID, 41, 51, @on
exec sp_trace_setevent @TraceID, 41, 4, @on
exec sp_trace_setevent @TraceID, 41, 12, @on
exec sp_trace_setevent @TraceID, 41, 60, @on
exec sp_trace_setevent @TraceID, 41, 5, @on
exec sp_trace_setevent @TraceID, 41, 13, @on
exec sp_trace_setevent @TraceID, 41, 29, @on
exec sp_trace_setevent @TraceID, 41, 61, @on
exec sp_trace_setevent @TraceID, 41, 6, @on
exec sp_trace_setevent @TraceID, 41, 14, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

--exec sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Server Profiler - 5f7b1556-d611-4865-a5b2-2a4ebbcfe62f'
exec sp_trace_setfilter @TraceID, 11, 0, 6, N'tet\asis'
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
