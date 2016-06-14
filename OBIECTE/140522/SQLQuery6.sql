USE [TEST]
GO

/****** Object:  Index [missing_index_377]    Script Date: 05/22/2014 15:32:53 ******/
CREATE NONCLUSTERED DROP INDEX [missing_index_377] ON [dbo].[antetBonuri] 
(
	[Chitanta] ASC,
	[Data_bon] ASC
)
INCLUDE ( [Casa_de_marcat],
[Numar_bon],
[Vinzator],
[Factura],
[Data_facturii],
[Tert],
[Gestiune],
[Contract],
[Comanda],
[IdAntetBon]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


