USE [TEST]
GO

/****** Object:  Index [antetBonuri1]    Script Date: 05/22/2014 15:32:45 ******/
CREATE NONCLUSTERED DROP INDEX [antetBonuri1] ON [dbo].[antetBonuri] 
(
	[Factura] ASC,
	[Data_facturii] ASC,
	[Chitanta] ASC,
	[Tert] ASC,
	[Casa_de_marcat] ASC,
	[Data_bon] ASC,
	[Numar_bon] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


