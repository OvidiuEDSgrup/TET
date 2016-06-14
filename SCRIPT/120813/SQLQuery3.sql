select * from sys.dm_exec_cursors(0) where name='crspozcon' --and session_id=@@SPID
--close crspozcon