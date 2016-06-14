/*
Missing Index Details from SQLQuery5.sql - ASIS.TET (TET\asis (67)) Executing...
The Query Processor estimates that implementing the following index could improve the query cost by 9.67852%.
*/

--/*
USE [tempdb]
GO
CREATE NONCLUSTERED INDEX [yso_furn_benef]
ON #docfac ([furn_benef])
INCLUDE ([nr_dvi])
GO
--*/
