USE [master]
GO
CREATE LOGIN [TET\roxana.vatajelu] FROM WINDOWS WITH DEFAULT_DATABASE=[TET]
GO
USE [IMPORT]
GO
USE [IMPORT]
GO
EXEC sp_addrolemember N'db_datareader', N'TET\roxana.vatajelu'
GO
USE [IMPORT]
GO
EXEC sp_addrolemember N'db_datawriter', N'TET\roxana.vatajelu'
GO
USE [ReportServer]
GO
USE [ReportServer]
GO
EXEC sp_addrolemember N'db_datareader', N'TET\roxana.vatajelu'
GO
USE [ReportServer]
GO
EXEC sp_addrolemember N'db_datawriter', N'TET\roxana.vatajelu'
GO
USE [ReportServerTempDB]
GO
USE [ReportServerTempDB]
GO
EXEC sp_addrolemember N'db_datareader', N'TET\roxana.vatajelu'
GO
USE [ReportServerTempDB]
GO
EXEC sp_addrolemember N'db_datawriter', N'TET\roxana.vatajelu'
GO
USE [tempdb]
GO
USE [tempdb]
GO
EXEC sp_addrolemember N'db_datareader', N'TET\roxana.vatajelu'
GO
USE [tempdb]
GO
EXEC sp_addrolemember N'db_datawriter', N'TET\roxana.vatajelu'
GO
USE [TET]
GO
USE [TET]
GO
EXEC sp_addrolemember N'db_datareader', N'TET\roxana.vatajelu'
GO
USE [TET]
GO
EXEC sp_addrolemember N'db_datawriter', N'TET\roxana.vatajelu'
GO
