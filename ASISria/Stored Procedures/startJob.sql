-- procedura verifica si porneste un job, daca acesta nu e running
create procedure startJob @JOB_NAME SYSNAME = N'ASIS_Job'
as
--DECLARE @JOB_NAME SYSNAME = N'ASIS_Job'; 
 
IF NOT EXISTS(     
        SELECT job.name, 
				job.job_id, 
				job.originating_server, 
				activity.run_requested_date, 
				DATEDIFF( SECOND, activity.run_requested_date, GETDATE() ) as Elapsed
		FROM msdb.dbo.sysjobs_view job
		JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
		JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
		JOIN(SELECT MAX( agent_start_date ) AS max_agent_start_date FROM msdb.dbo.syssessions ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date 
		WHERE  run_requested_date IS NOT NULL AND stop_execution_date IS NULL
		and job.name = @JOB_NAME 
        )
BEGIN      
    PRINT 'Starting job ''' + @JOB_NAME + ''''; 
    EXEC msdb.dbo.sp_start_job @JOB_NAME; 
END 
ELSE 
BEGIN 
    PRINT 'Job ''' + @JOB_NAME + ''' is already started '; 
END 

-- exec startjob
