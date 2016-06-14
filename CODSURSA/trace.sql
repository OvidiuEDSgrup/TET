SELECT count(*) FROM :: fn_trace_getinfo(default) WHERE property = 5 and value = 1
SELECT * FROM :: fn_trace_getinfo(default)

EXEC sp_trace_setstatus 5, @status = 0
EXEC sp_trace_setstatus 5, @status = 2