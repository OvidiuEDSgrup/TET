EXEC sp_resetstatus 'ALFINCOOL'
GO
ALTER DATABASE ALFINCOOL SET EMERGENCY
DBCC checkdb('ALFINCOOL')
ALTER DATABASE ALFINCOOL SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CheckDB ('ALFINCOOL', REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE ALFINCOOL SET MULTI_USER

GO

