alter database testov set single_user with rollback immediate
go
RESTORE DATABASE [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\TET\TET_backup_2013_07_05_070022_9914627.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 10
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\TET\TET_backup_2013_07_05_080001_5803808.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10,  STOPAT = N'2013-07-05T08:03:00'
GO
