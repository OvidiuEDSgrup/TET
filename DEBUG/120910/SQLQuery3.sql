select * from sys.dm_exec_sessions s where s.session_id in (88,89,128,117)
--kill 117
select * from sys.dm_os_waiting_tasks s where s.session_id=117