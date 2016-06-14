USE [master]
GO
ALTER DATABASE [TESTOV] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_070022_9914627.bak' 
WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 10
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_080001_5803808.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, NORECOVERY
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_100016_4665636.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, NORECOVERY
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_120009_2001574.trn ' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, NORECOVERY
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_140006_0861801.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, NORECOVERY
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_160027_4767931.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, STOPAT = N'2013-07-05T15:27:30'
GO
RESTORE LOG [TESTOV] FROM  DISK = N'D:\BAZA_DATE_SALVARE\TET\TET_backup_2013_07_05_180002_8816999.trn ' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, STOPAT = N'2013-07-05T08:01:00'
GO