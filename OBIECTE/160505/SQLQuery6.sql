/*
Missing Index Details from SQLQuery5.sql - ASIS.TET (TET\asis (67)) Executing...
The Query Processor estimates that implementing the following index could improve the query cost by 19.5191%.
*/

--/*
USE [TET]
GO
CREATE NONCLUSTERED INDEX [yso_grupa_tert]
ON [dbo].[terti] ([Subunitate],[Grupa])
INCLUDE ([Tert])
GO
--*/
