RESTORE DATABASE [TESTOV] FROM  DISK = N'E:\SQL_BKP\DEPANARI\TET_backup_2015_06_30_070001_1027617.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD, REPLACE,  STATS = 10
GO
RESTORE LOG [TESTOV] FROM  DISK = N'E:\SQL_BKP\DEPANARI\TET_backup_2015_06_30_080001_4053463.trn' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
GO
RESTORE LOG [TESTOV] FROM  DISK = N'E:\SQL_BKP\DEPANARI\TET_backup_2015_06_30_100000_9580938.trn' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
GO
RESTORE LOG [TESTOV] FROM  DISK = N'E:\SQL_BKP\DEPANARI\TET_backup_2015_06_30_120001_1504618.trn' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
GO
RESTORE LOG [TESTOV] FROM  DISK = N'E:\SQL_BKP\DEPANARI\TET_backup_2015_06_30_140000_8436138.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10, STOPAT = N'2015-06-30T13:30:00'
GO
