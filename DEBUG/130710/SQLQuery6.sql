USE [master]
GO
ALTER DATABASE [TESTOV] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\TET\TET_backup_2013_07_09_070009_2612447.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
--RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\TET\TET_backup_2013_07_09_080003_5599590.trn' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
--GO
--RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\TET\TET_backup_2013_07_09_100003_7588965.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10
--GO

