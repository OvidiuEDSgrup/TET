/*
Missing Index Details from SQLQuery5.sql - ASIS.TET (TET\asis (67))
The Query Processor estimates that implementing the following index could improve the query cost by 27.3353%.
*/

--/*
USE [tempdb]
GO
CREATE NONCLUSTERED INDEX [yso_sub_tip_idpoz]
ON dbo.#docfac ([subunitate],[tip])
INCLUDE ([idPozitieDoc])
GO
--*/
