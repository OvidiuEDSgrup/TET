/*
Missing Index Details from SQLQuery5.sql - ASIS.TET (TET\asis (67)) Executing...
The Query Processor estimates that implementing the following index could improve the query cost by 75.4598%.
*/

--/*
USE [tempdb]
GO
CREATE NONCLUSTERED INDEX [yso_sub_tip]
ON dbo.#docfac ([subunitate],[tip])
INCLUDE ([tert],[factura],[numar],[data],[numar_pozitie],[data_facturii])
GO
--*/
