/*
Missing Index Details from SQLQuery5.sql - ASIS.TET (TET\asis (67)) Executing...
The Query Processor estimates that implementing the following index could improve the query cost by 10.1926%.
*/

--/*
USE [tempdb]
GO
CREATE NONCLUSTERED INDEX [yso_tip_cont_de_tert]
ON dbo.#docfac ([subunitate],[tip],[cont_de_tert])
INCLUDE ([numar],[data])
GO
--*/
