/****** Object:  Index [Unic]    Script Date: 01/19/2012 11:44:28 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[facturi]') AND name = N'Unic')
DROP INDEX [Unic] ON [dbo].[facturi] WITH ( ONLINE = OFF )
GO


/****** Object:  Table [dbo].[facturi]    Script Date: 01/19/2012 11:42:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[facturi]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[facturi](
	[Subunitate] [char](9) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Tip] [binary](1) NOT NULL,
	[Factura] [char](25) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Valoare] [float] NOT NULL,
	[TVA_11] [float] NOT NULL,
	[TVA_22] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Valoare_valuta] [float] NOT NULL,
	[Achitat] [float] NOT NULL,
	[Sold] [float] NOT NULL,
	[Cont_de_tert] [char](13) NOT NULL,
	[Achitat_valuta] [float] NOT NULL,
	[Sold_valuta] [float] NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Data_ultimei_achitari] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[facturi]') AND name = N'Unic')
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [dbo].[facturi] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Factura] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[facturi]') AND name = N'Jurnale_TVA')
CREATE NONCLUSTERED INDEX [Jurnale_TVA] ON [dbo].[facturi] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[facturi]') AND name = N'Sub_Tip_Tert')
CREATE NONCLUSTERED INDEX [Sub_Tip_Tert] ON [dbo].[facturi] 
(
	[Subunitate] ASC,
	[Tert] ASC,
	[Tip] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
