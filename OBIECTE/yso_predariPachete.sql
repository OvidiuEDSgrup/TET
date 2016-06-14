drop proc yso_predariPachete 
GO
--exec yso.predariPachete '5048'
CREATE PROC yso_predariPachete @cHostId char(10) AS 
EXEC yso.predariPachete @cHostId=@cHostId