USE [TET]
GO

/****** Object:  Table [yso].[stocuri]    Script Date: 12/12/2011 08:50:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [yso].[stocuri](
	[Subunitate] [char](9) NOT NULL,
	[Tip_gestiune] [char](1) NOT NULL,
	[Cod_gestiune] [char](20) NOT NULL,
	[Cod] [char](20) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Cod_intrare] [char](13) NOT NULL,
	[Pret] [float] NOT NULL,
	[Stoc_initial] [float] NOT NULL,
	[Intrari] [float] NOT NULL,
	[Iesiri] [float] NOT NULL,
	[Data_ultimei_iesiri] [datetime] NOT NULL,
	[Stoc] [float] NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Data_expirarii] [datetime] NOT NULL,
	[Stoc_ce_se_calculeaza] [float] NOT NULL,
	[Are_documente_in_perioada] [bit] NOT NULL,
	[TVA_neexigibil] [real] NOT NULL,
	[Pret_cu_amanuntul] [float] NOT NULL,
	[Locatie] [char](30) NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Furnizor] [char](13) NOT NULL,
	[Lot] [char](20) NOT NULL,
	[Stoc_initial_UM2] [float] NOT NULL,
	[Intrari_UM2] [float] NOT NULL,
	[Iesiri_UM2] [float] NOT NULL,
	[Stoc_UM2] [float] NOT NULL,
	[Stoc2_ce_se_calculeaza] [float] NOT NULL,
	[Val1] [float] NOT NULL,
	[Alfa1] [char](30) NOT NULL,
	[Data1] [datetime] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [TET]
GO

/****** Object:  Index [Unic]    Script Date: 12/12/2011 08:51:10 ******/
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [yso].[stocuri] 
(
	[Subunitate] ASC,
	[Tip_gestiune] ASC,
	[Cod_gestiune] ASC,
	[Cod] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [TET]
GO

/****** Object:  Index [FIFO_dataexp]    Script Date: 12/12/2011 08:51:38 ******/
CREATE UNIQUE NONCLUSTERED INDEX [FIFO] ON [yso].[stocuri] 
(
	[Subunitate] ASC,
	[Tip_gestiune] ASC,
	[Cod_gestiune] ASC,
	[Cod] ASC,
	[Data] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [LIFO] ON [yso].[stocuri] 
(
	[Subunitate] ASC,
	[Tip_gestiune] ASC,
	[Cod_gestiune] ASC,
	[Cod] ASC,
	[Data] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [TET]
GO

/****** Object:  Index [Locatie]    Script Date: 12/12/2011 08:58:32 ******/
CREATE NONCLUSTERED INDEX [Locatie] ON [yso].[stocuri] 
(
	[Locatie] ASC,
	[Stoc] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [TET]
GO

/****** Object:  Index [Pentru_preturi]    Script Date: 12/12/2011 08:58:44 ******/
CREATE NONCLUSTERED INDEX [Pentru_preturi] ON [yso].[stocuri] 
(
	[Subunitate] ASC,
	[Cod] ASC,
	[Pret] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [TET]
GO

/****** Object:  Index [Sub_Cod_Stoc]    Script Date: 12/12/2011 08:58:55 ******/
CREATE NONCLUSTERED INDEX [Sub_Cod_Stoc] ON [yso].[stocuri] 
(
	[Subunitate] ASC,
	[Cod] ASC,
	[Stoc] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


USE [TET]
GO

/****** Object:  Index [FIFO_dataexp]    Script Date: 12/12/2011 09:04:31 ******/
CREATE UNIQUE NONCLUSTERED INDEX [FIFO_dataexp] ON [yso].[stocuri] 
(
	[Subunitate] ASC,
	[Tip_gestiune] ASC,
	[Cod_gestiune] ASC,
	[Cod] ASC,
	[Data_expirarii] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

