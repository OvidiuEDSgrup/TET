USE [master]
GO
ALTER DATABASE [TET] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [TET] FROM  DISK = N'D:\BAZA_DATE_SALVARE\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\TET\TET_backup_2013_10_31_121801_1643830.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
