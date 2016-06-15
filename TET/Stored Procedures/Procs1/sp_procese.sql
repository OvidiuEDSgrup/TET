CREATE procedure [dbo].[sp_procese]
       @loginame sysname = NULL --or 'active'
as

select t.text,s.cpu, physical_io, s.spid, s.nt_username, s.loginame, s.hostname, s.program_name, s.hostprocess, s.*
		--, * 
	from master.dbo.sysprocesses s
		join sys.dm_exec_requests r on r.session_id=s.spid
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
	where  s.status not in ('sleeping', 'background')
	order by s.cpu desc
