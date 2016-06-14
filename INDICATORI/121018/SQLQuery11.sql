/*
Missing Index Details from SQLQuery10.sql - ASIS.TET (TET\ASIS (66))
The Query Processor estimates that implementing the following index could improve the query cost by 43.4652%.
*/

--/*
USE [TET]
GO
CREATE NONCLUSTERED INDEX [yso_tb_tip]
ON [dbo].[pozdoc] ([Tip])
INCLUDE ([Subunitate],[Cod],[Data],[Gestiune],[Cantitate],[Pret_de_stoc],[Pret_vanzare],[Cod_intrare],[Loc_de_munca],[Cont_venituri],[Tert],[Accize_cumparare])
GO
--*/
