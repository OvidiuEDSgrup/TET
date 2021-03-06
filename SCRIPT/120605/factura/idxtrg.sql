USE [TET]
GO
/****** Object:  Table [dbo].[ImpExtras]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ImpExtras]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ImpExtras](
	[Data] [datetime] NOT NULL,
	[Cont_antet] [char](13) NOT NULL,
	[Cod_operatie] [char](3) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Efect] [char](10) NOT NULL,
	[Cont_coresp] [char](13) NOT NULL,
	[Suma_valuta] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Suma] [float] NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Nr_pozitie] [int] NOT NULL,
	[Aux1] [char](50) NOT NULL,
	[Aux2] [char](50) NOT NULL,
	[Aux3] [char](50) NOT NULL,
	[Aux4] [char](50) NOT NULL,
	[Aux5] [char](50) NOT NULL,
	[Aux6] [char](50) NOT NULL,
	[Aux7] [char](50) NOT NULL,
	[Aux8] [char](50) NOT NULL,
	[Aux9] [char](50) NOT NULL,
	[Aux10] [char](50) NOT NULL,
	[Aux11] [char](50) NOT NULL,
	[Aux12] [char](50) NOT NULL,
	[Expandare] [bit] NOT NULL,
	[Stare] [smallint] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ImpExtras]') AND name = N'Unic')
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [dbo].[ImpExtras] 
(
	[Data] ASC,
	[Nr_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[impcurs]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[impcurs]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[impcurs](
	[Cod] [char](30) NOT NULL,
	[Cod_intrare] [char](13) NOT NULL,
	[Den_original] [char](30) NOT NULL,
	[Den_romana] [char](30) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Serie] [char](9) NOT NULL,
	[An_fabr] [smallint] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Pret] [float] NOT NULL,
	[Dobanda] [float] NOT NULL,
	[Nr_sumara] [char](8) NOT NULL,
	[Data_sumara] [datetime] NOT NULL,
	[Curs_sumara] [float] NOT NULL,
	[Furnizor] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Data_fact] [datetime] NOT NULL,
	[DVI] [char](8) NOT NULL,
	[Data_DVI] [datetime] NOT NULL,
	[Curs_DVI] [float] NOT NULL,
	[Transportator] [char](13) NOT NULL,
	[Fact_transp] [char](20) NOT NULL,
	[Data_fact_transp] [datetime] NOT NULL,
	[Val_transp] [float] NOT NULL,
	[Stare] [char](1) NOT NULL,
	[Tip_operatie] [char](1) NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Valoare] [float] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](13) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[impcurs]') AND name = N'Impcurs1')
CREATE UNIQUE CLUSTERED INDEX [Impcurs1] ON [dbo].[impcurs] 
(
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[impcurs]') AND name = N'Impcurs2')
CREATE UNIQUE NONCLUSTERED INDEX [Impcurs2] ON [dbo].[impcurs] 
(
	[Cod] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[impcurs]') AND name = N'Impcurs3')
CREATE UNIQUE NONCLUSTERED INDEX [Impcurs3] ON [dbo].[impcurs] 
(
	[Nr_sumara] ASC,
	[Data_sumara] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[impcurs]') AND name = N'Impcurs4')
CREATE NONCLUSTERED INDEX [Impcurs4] ON [dbo].[impcurs] 
(
	[DVI] ASC,
	[Data_DVI] ASC,
	[Stare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[generareplati]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[generareplati]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[generareplati](
	[Tip] [char](1) NOT NULL,
	[Element] [char](1) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Numar_document] [char](20) NOT NULL,
	[Numar_ordin] [char](20) NOT NULL,
	[Suma_platita] [float] NOT NULL,
	[Detalii_plata] [char](200) NOT NULL,
	[Cont_platitor] [char](20) NOT NULL,
	[IBAN_beneficiar] [char](50) NOT NULL,
	[Banca_beneficiar] [char](100) NOT NULL,
	[Alfa1] [char](200) NOT NULL,
	[Alfa2] [char](200) NOT NULL,
	[Alfa3] [char](200) NOT NULL,
	[Val1] [float] NOT NULL,
	[Val2] [float] NOT NULL,
	[Val3] [float] NOT NULL,
	[Data1] [datetime] NOT NULL,
	[Data2] [datetime] NOT NULL,
	[Data3] [datetime] NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Loc_de_munca] [varchar](9) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[generareplati]') AND name = N'Factura')
CREATE NONCLUSTERED INDEX [Factura] ON [dbo].[generareplati] 
(
	[Tip] ASC,
	[Element] ASC,
	[Tert] ASC,
	[Factura] ASC,
	[Stare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[generareplati]') AND name = N'Generare plati')
CREATE NONCLUSTERED INDEX [Generare plati] ON [dbo].[generareplati] 
(
	[Tip] ASC,
	[Numar_document] ASC,
	[Data] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[facturi]    Script Date: 12/16/2011 17:08:31 ******/
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
	[Factura] [char](20) NOT NULL,
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
/****** Object:  Table [dbo].[factrate]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factrate]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[factrate](
	[Subunitate] [char](9) NOT NULL,
	[Tip_contract] [char](2) NOT NULL,
	[Data_contract] [datetime] NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Numar_rata] [smallint] NOT NULL,
	[Tip_plata] [char](2) NOT NULL,
	[Valoare] [float] NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Suma_TVA] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[factura] [char](20) NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Cont_deb] [char](13) NOT NULL,
	[Cont_cred] [char](13) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Curs_calcul] [float] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factrate]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[factrate] 
(
	[Subunitate] ASC,
	[Tip_contract] ASC,
	[Data_contract] ASC,
	[Contract] ASC,
	[Tert] ASC,
	[Numar_rata] ASC,
	[Tip_plata] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factrate]') AND name = N'Document')
CREATE NONCLUSTERED INDEX [Document] ON [dbo].[factrate] 
(
	[Numar_document] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factrate]') AND name = N'Factura')
CREATE NONCLUSTERED INDEX [Factura] ON [dbo].[factrate] 
(
	[factura] ASC,
	[Data_facturii] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[factposleg]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factposleg]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[factposleg](
	[Nr_bon] [int] NOT NULL,
	[casa_de_marcat] [smallint] NOT NULL,
	[data] [datetime] NOT NULL,
	[cod_fiscal] [char](16) NOT NULL,
	[Factura] [char](15) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[factpos]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factpos]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[factpos](
	[cod_fiscal] [char](16) NOT NULL,
	[nr_inmatr_registru] [char](20) NOT NULL,
	[denumire] [char](30) NOT NULL,
	[judet] [char](20) NOT NULL,
	[localitate] [char](35) NOT NULL,
	[sediu] [char](60) NOT NULL,
	[cont] [char](35) NOT NULL,
	[banca] [char](20) NOT NULL,
	[nume_delegat] [char](30) NOT NULL,
	[CNP_delegat] [char](16) NOT NULL,
	[serie_bi_delegat] [char](4) NOT NULL,
	[numar_bi_delegat] [char](10) NOT NULL,
	[eliberat_bi_delegat] [char](30) NOT NULL,
	[mijloc_transport] [char](10) NOT NULL,
	[nr_transport] [char](15) NOT NULL,
	[data_expedierii] [datetime] NOT NULL,
	[ora_expedierii] [char](6) NOT NULL,
	[observatii] [char](50) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[factimpl]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factimpl]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[factimpl](
	[Subunitate] [char](9) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Tip] [binary](1) NOT NULL,
	[Factura] [char](20) NOT NULL,
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
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factimpl]') AND name = N'Unic')
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [dbo].[factimpl] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Factura] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factimpl]') AND name = N'Jurnale_TVA')
CREATE NONCLUSTERED INDEX [Jurnale_TVA] ON [dbo].[factimpl] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factimpl]') AND name = N'Sub_Tip_Tert')
CREATE NONCLUSTERED INDEX [Sub_Tip_Tert] ON [dbo].[factimpl] 
(
	[Subunitate] ASC,
	[Tert] ASC,
	[Tip] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[factext]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factext]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[factext](
	[tert] [char](13) NOT NULL,
	[factura] [char](20) NOT NULL,
	[nr_DVE] [char](13) NOT NULL,
	[data_DVE] [datetime] NOT NULL,
	[nr_DIV] [char](13) NOT NULL,
	[data_DIV] [datetime] NOT NULL,
	[factura_externa] [char](20) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[factext]') AND name = N'unic')
CREATE UNIQUE CLUSTERED INDEX [unic] ON [dbo].[factext] 
(
	[tert] ASC,
	[factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[extprogpl]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[extprogpl]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[extprogpl](
	[Tip] [char](1) NOT NULL,
	[Element] [char](1) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Numar_document] [char](20) NOT NULL,
	[Suma_platita] [float] NOT NULL,
	[Detalii_plata] [char](200) NOT NULL,
	[Cont_platitor] [char](20) NOT NULL,
	[IBAN_beneficiar] [char](50) NOT NULL,
	[Banca_beneficiar] [char](100) NOT NULL,
	[Alfa1] [char](200) NOT NULL,
	[Alfa2] [char](200) NOT NULL,
	[Alfa3] [char](200) NOT NULL,
	[Val1] [float] NOT NULL,
	[Val2] [float] NOT NULL,
	[Val3] [float] NOT NULL,
	[Data1] [datetime] NOT NULL,
	[Data2] [datetime] NOT NULL,
	[Data3] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[extprogpl]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[extprogpl] 
(
	[Tip] ASC,
	[Element] ASC,
	[Data] ASC,
	[Tert] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pozplin]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozplin]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[pozplin](
	[Subunitate] [char](9) NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Numar] [char](10) NOT NULL,
	[Plata_incasare] [char](2) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[Suma] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Suma_valuta] [float] NOT NULL,
	[Curs_la_valuta_facturii] [float] NOT NULL,
	[TVA11] [float] NOT NULL,
	[TVA22] [float] NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Cont_dif] [char](13) NOT NULL,
	[Suma_dif] [float] NOT NULL,
	[Achit_fact] [float] NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozplin]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[pozplin] 
(
	[Subunitate] ASC,
	[Cont] ASC,
	[Data] ASC,
	[Numar_pozitie] ASC,
	[Numar] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozplin]') AND name = N'Jurnal')
CREATE NONCLUSTERED INDEX [Jurnal] ON [dbo].[pozplin] 
(
	[Subunitate] ASC,
	[Cont] ASC,
	[Data] ASC,
	[Jurnal] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozplin]') AND name = N'Sub_Tert_Factura')
CREATE NONCLUSTERED INDEX [Sub_Tert_Factura] ON [dbo].[pozplin] 
(
	[Subunitate] ASC,
	[Tert] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [plinfac]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plinfac]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[plinfac] on [dbo].[pozplin] for update,insert,delete with append as 
begin
    insert into facturi select subunitate,max(loc_de_munca), (case when plata_incasare in (''IB'',''IR'',''PS'') then 0x46 else 0x54 end), 
	factura,tert,max(data),max(data),0,0,0,max(valuta),max(curs),0,0,0,max(cont_corespondent),0,0,max(comanda),max(data) 
	from inserted where plata_incasare in (''PF'',''IB'',''PR'',''IR'',''PS'',''IS'') and factura not in (select factura from facturi where 
	subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when inserted.plata_incasare in (''IB'',''IR'',''PS'') 
	then 0x46 else 0x54 end))
   group by subunitate,plata_incasare,tert,factura

declare @valoare float,@valoarev float,@dataach datetime
declare @csub char(9),@ctip char(2),@ddata datetime,@ctert char(13),@cfactura char(20),@semn int,@suma float,
             @sumav float,@sumad float,@valuta char(3),@curs float,@achv float
declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@tipf binary,@gvaluta char(3),@gcurs float, @gfetch int

declare tmp cursor for
select subunitate,plata_incasare,data,tert,factura, (case when plata_incasare in (''PS'',''IS'') then -1 else 1 end), suma,suma_valuta,suma_dif,valuta,curs,achit_fact
from inserted where plata_incasare in (''IB'',''PF'',''PR'',''IR'',''PS'',''IS'') union all
select subunitate,plata_incasare,data,tert,factura, (case when plata_incasare in (''PS'',''IS'') then 1 else -1 end), suma,suma_valuta,suma_dif,valuta,curs, achit_fact
from deleted where plata_incasare in (''IB'',''PF'',''PR'',''IR'',''PS'',''IS'')
order by subunitate,plata_incasare,tert,factura

open tmp
fetch next from tmp into @csub,@ctip,@ddata,@ctert,@cfactura,@semn,@suma,@sumav,@sumad,@valuta,@curs,@achv
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gtip=@ctip
set @gvaluta=@valuta
set @gcurs=@curs
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @DataAch=''''
	while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
	begin
		if @ctip=''PF'' or @ctip=''PR'' or @ctip=''IS''
			set @tipf=0x54
		else
			set @tipf=0x46
		if @valuta='''' 
			set @valoare=@valoare+@suma*@semn
		else 
			begin
				set @valoare=@valoare+(@suma-@Sumad)*@semn
				set @valoarev=@valoarev+@achv*@semn
			end
		if @semn=1 set @dataach=@ddata
		fetch next from tmp
		    into @csub,@ctip,@ddata,@ctert,@cfactura,@semn,@suma,@sumav,@sumad,@valuta,@curs,@achv
		set @gfetch=@@fetch_status
	end
	update facturi set achitat=achitat+@valoare, sold=sold-@valoare, data_ultimei_achitari=@dataach /*,valuta='''',curs=0*/
	where subunitate=@gsub and tip=@tipf and tert=@gtert and factura=@gfactura

	update facturi set /*valuta=@gvaluta,curs=@gcurs,*/
		achitat_valuta=achitat_valuta+@valoarev, sold_valuta=sold_valuta-@valoarev  
	from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura
			and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1 
	/*delete from facturi where subunitate=@gsub and tip=@tipf and tert=@gtert and factura=@gfactura 
		and valoare=0 and tva_22=0 and tva_11=0 and achitat=0 and valoare_valuta=0 and achitat_valuta=0
	if @tipf=0x54
		update terti set sold_ca_furnizor=sold_ca_furnizor-@valoare where tert=@gtert
	else
		update terti set sold_ca_beneficiar=sold_ca_beneficiar-@valoare where tert=@gtert*/
	set @gtert=@ctert
	set @gsub=@csub
	set @gfactura=@cfactura
	set @gtip=@ctip
	set @gvaluta=@valuta
	set @gcurs=@curs
end

close tmp
deallocate tmp
end'
GO
/****** Object:  Table [dbo].[sysspp]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspp]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[sysspp](
	[Host_id] [char](10) NOT NULL,
	[Host_name] [char](30) NOT NULL,
	[Aplicatia] [char](30) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL,
	[Stergator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Numar] [char](10) NOT NULL,
	[Plata_incasare] [char](2) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[Suma] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Suma_valuta] [float] NOT NULL,
	[Curs_la_valuta_facturii] [float] NOT NULL,
	[TVA11] [float] NOT NULL,
	[TVA22] [float] NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Cont_dif] [char](13) NOT NULL,
	[Suma_dif] [float] NOT NULL,
	[Achit_fact] [float] NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sysspd]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspd]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[sysspd](
	[Host_id] [char](10) NOT NULL,
	[Host_name] [char](30) NOT NULL,
	[Aplicatia] [char](30) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL,
	[Stergator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Cod] [char](20) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret_valuta] [float] NOT NULL,
	[Pret_de_stoc] [float] NOT NULL,
	[Adaos] [real] NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Pret_cu_amanuntul] [float] NOT NULL,
	[TVA_deductibil] [float] NOT NULL,
	[Cota_TVA] [smallint] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Cod_intrare] [char](13) NOT NULL,
	[Cont_de_stoc] [char](13) NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[TVA_neexigibil] [smallint] NOT NULL,
	[Pret_amanunt_predator] [float] NOT NULL,
	[Tip_miscare] [char](1) NOT NULL,
	[Locatie] [char](30) NOT NULL,
	[Data_expirarii] [datetime] NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Barcod] [char](30) NOT NULL,
	[Cont_intermediar] [char](13) NOT NULL,
	[Cont_venituri] [char](13) NOT NULL,
	[Discount] [real] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Gestiune_primitoare] [char](13) NOT NULL,
	[Numar_DVI] [char](25) NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Grupa] [char](13) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Procent_vama] [real] NOT NULL,
	[Suprataxe_vama] [float] NOT NULL,
	[Accize_cumparare] [float] NOT NULL,
	[Accize_datorate] [float] NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sysspcon]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspcon]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[sysspcon](
	[Host_id] [char](10) NOT NULL,
	[Host_name] [char](30) NOT NULL,
	[Aplicatia] [char](30) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL,
	[Stergator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Punct_livrare] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Cod] [char](30) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret] [float] NOT NULL,
	[Pret_promotional] [float] NOT NULL,
	[Discount] [real] NOT NULL,
	[Termen] [datetime] NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Cant_disponibila] [float] NOT NULL,
	[Cant_aprobata] [float] NOT NULL,
	[Cant_realizata] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Cota_TVA] [smallint] NOT NULL,
	[Suma_TVA] [float] NOT NULL,
	[Mod_de_plata] [char](8) NOT NULL,
	[UM] [char](1) NOT NULL,
	[Zi_scadenta_din_luna] [smallint] NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Utilizator] [char](10) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sysspa]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysspa]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[sysspa](
	[Host_id] [char](10) NOT NULL,
	[Host_name] [char](30) NOT NULL,
	[Aplicatia] [char](30) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL,
	[Stergator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Factura_stinga] [char](20) NOT NULL,
	[Factura_dreapta] [char](20) NOT NULL,
	[Cont_deb] [char](13) NOT NULL,
	[Cont_cred] [char](13) NOT NULL,
	[Suma] [float] NOT NULL,
	[TVA11] [float] NOT NULL,
	[TVA22] [float] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Tert_beneficiar] [char](13) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Suma_valuta] [float] NOT NULL,
	[Cont_dif] [char](13) NOT NULL,
	[suma_dif] [float] NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Data_fact] [datetime] NOT NULL,
	[Data_scad] [datetime] NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Achit_fact] [float] NOT NULL,
	[Dif_TVA] [float] NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[syssmm]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[syssmm]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[syssmm](
	[Host_id] [char](10) NOT NULL,
	[Host_name] [char](30) NOT NULL,
	[Aplicatia] [char](30) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL,
	[Stergator] [char](10) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Data_lunii_de_miscare] [datetime] NOT NULL,
	[Numar_de_inventar] [char](13) NOT NULL,
	[Tip_miscare] [char](3) NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Data_miscarii] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Pret] [float] NOT NULL,
	[TVA] [float] NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[Loc_de_munca_primitor] [char](13) NOT NULL,
	[Gestiune_primitoare] [char](13) NOT NULL,
	[Diferenta_de_valoare] [float] NOT NULL,
	[Data_sfarsit_conservare] [datetime] NOT NULL,
	[Subunitate_primitoare] [char](40) NOT NULL,
	[Procent_inchiriere] [real] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sysscon]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysscon]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[sysscon](
	[Host_id] [char](10) NOT NULL,
	[Host_name] [char](30) NOT NULL,
	[Aplicatia] [char](30) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL,
	[Stergator] [char](10) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Punct_livrare] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Stare] [char](1) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Termen] [datetime] NOT NULL,
	[Scadenta] [smallint] NOT NULL,
	[Discount] [real] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Mod_plata] [char](1) NOT NULL,
	[Mod_ambalare] [char](1) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Total_contractat] [float] NOT NULL,
	[Total_TVA] [float] NOT NULL,
	[Contract_coresp] [char](20) NOT NULL,
	[Mod_penalizare] [char](13) NOT NULL,
	[Procent_penalizare] [real] NOT NULL,
	[Procent_avans] [real] NOT NULL,
	[Avans] [float] NOT NULL,
	[Nr_rate] [smallint] NOT NULL,
	[Val_reziduala] [float] NOT NULL,
	[Sold_initial] [float] NOT NULL,
	[Cod_dobanda] [char](20) NOT NULL,
	[Dobanda] [real] NOT NULL,
	[Incasat] [float] NOT NULL,
	[Responsabil] [char](20) NOT NULL,
	[Responsabil_tert] [char](20) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Data_rezilierii] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[seriidocrs]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[seriidocrs]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[seriidocrs](
	[loc_de_munca] [char](9) NOT NULL,
	[chit_inf] [char](20) NOT NULL,
	[chit_sup] [char](20) NOT NULL,
	[fact_inf] [char](20) NOT NULL,
	[fact_sup] [char](20) NOT NULL,
	[data_eliberarii] [datetime] NOT NULL,
	[data_consumarii] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[seriidocrs]') AND name = N'lm_chit_fact')
CREATE UNIQUE CLUSTERED INDEX [lm_chit_fact] ON [dbo].[seriidocrs] 
(
	[loc_de_munca] ASC,
	[chit_inf] ASC,
	[fact_inf] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[selfactachit]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[selfactachit]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[selfactachit](
	[HostID] [char](8) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Tip] [binary](1) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Selectat] [bit] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[selfactachit]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[selfactachit] 
(
	[HostID] ASC,
	[Subunitate] ASC,
	[Tip] ASC,
	[Factura] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[selfactachit]') AND name = N'Sub_Tert_Tip')
CREATE NONCLUSTERED INDEX [Sub_Tert_Tip] ON [dbo].[selfactachit] 
(
	[HostID] ASC,
	[Subunitate] ASC,
	[Tert] ASC,
	[Tip] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[docsters]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[docsters]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[docsters](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Cod] [char](20) NOT NULL,
	[Cod_intrare] [char](13) NOT NULL,
	[Gestiune_primitoare] [char](9) NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Cont_cor] [char](13) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret] [float] NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Jurnal] [char](3) NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Data_stergerii] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[docsters]') AND name = N'Sterse')
CREATE UNIQUE CLUSTERED INDEX [Sterse] ON [dbo].[docsters] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Numar] ASC,
	[Data] ASC,
	[Data_stergerii] ASC,
	[Cod] ASC,
	[Cod_intrare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[docsters]') AND name = N'Data_stergerii')
CREATE NONCLUSTERED INDEX [Data_stergerii] ON [dbo].[docsters] 
(
	[Data_stergerii] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ExpImpExtras]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExpImpExtras]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ExpImpExtras](
	[Data_import] [datetime] NOT NULL,
	[Pozitie_import] [int] NOT NULL,
	[Tert_import] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Suma] [float] NOT NULL,
	[Pozitie_expandare] [int] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ExpImpExtras]') AND name = N'Unic')
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [dbo].[ExpImpExtras] 
(
	[Data_import] ASC,
	[Pozitie_import] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[adocsters]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[adocsters]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[adocsters](
	[Subunitate] [char](9) NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Factura_stinga] [char](20) NOT NULL,
	[Factura_dreapta] [char](20) NOT NULL,
	[Cont_deb] [char](13) NOT NULL,
	[Cont_cred] [char](13) NOT NULL,
	[Suma] [float] NOT NULL,
	[TVA11] [float] NOT NULL,
	[TVA22] [float] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Tert_beneficiar] [char](13) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Comanda] [char](20) NOT NULL,
	[Data_fact] [datetime] NOT NULL,
	[Data_scad] [datetime] NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Data_stergerii] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[adocsters]') AND name = N'Data_stergerii')
CREATE NONCLUSTERED INDEX [Data_stergerii] ON [dbo].[adocsters] 
(
	[Data_stergerii] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[adocsters]') AND name = N'Sterse')
CREATE UNIQUE NONCLUSTERED INDEX [Sterse] ON [dbo].[adocsters] 
(
	[Subunitate] ASC,
	[Numar_document] ASC,
	[Data] ASC,
	[Tip] ASC,
	[Data_stergerii] ASC,
	[Numar_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[combPozd]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[combPozd]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[combPozd](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Cod] [char](20) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret_valuta] [float] NOT NULL,
	[Pret_de_stoc] [float] NOT NULL,
	[Adaos] [real] NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Pret_cu_amanuntul] [float] NOT NULL,
	[TVA_deductibil] [float] NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Cod_intrare] [char](13) NOT NULL,
	[Cont_de_stoc] [char](13) NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[TVA_neexigibil] [real] NOT NULL,
	[Pret_amanunt_predator] [float] NOT NULL,
	[Tip_miscare] [char](1) NOT NULL,
	[Locatie] [char](13) NOT NULL,
	[Data_expirarii] [datetime] NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](13) NOT NULL,
	[Barcod] [char](13) NOT NULL,
	[Cont_intermediar] [char](13) NOT NULL,
	[Cont_venituri] [char](13) NOT NULL,
	[Discount] [real] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Gestiune_primitoare] [char](9) NOT NULL,
	[Numar_DVI] [char](13) NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Grupa] [char](13) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Procent_vama] [real] NOT NULL,
	[Suprataxe_vama] [float] NOT NULL,
	[Accize_cumparare] [float] NOT NULL,
	[Accize_datorate] [float] NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Jurnal] [char](3) NOT NULL,
	[Terminal] [smallint] NOT NULL,
	[Serie] [char](20) NOT NULL,
	[Stoc] [float] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[combPozd]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[combPozd] 
(
	[Subunitate] ASC,
	[Terminal] ASC,
	[Gestiune] ASC,
	[Serie] ASC,
	[Cod] ASC,
	[Pret_valuta] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[avnefac]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[avnefac]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[avnefac](
	[Terminal] [char](10) NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](20) NOT NULL,
	[Cod_gestiune] [char](9) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Cod_tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Contractul] [char](20) NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Comanda] [char](13) NOT NULL,
	[Gestiune_primitoare] [char](9) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Valoare] [float] NOT NULL,
	[Valoare_valuta] [float] NOT NULL,
	[Tva_11] [float] NOT NULL,
	[Tva_22] [float] NOT NULL,
	[Cont_beneficiar] [char](13) NOT NULL,
	[Discount] [real] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[avnefac]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[avnefac] 
(
	[Terminal] ASC,
	[Subunitate] ASC,
	[Tip] ASC,
	[Numar] ASC,
	[Cod_gestiune] ASC,
	[Data] ASC,
	[Contractul] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[antetBonuri]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[antetBonuri]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[antetBonuri](
	[Casa_de_marcat] [smallint] NOT NULL,
	[Chitanta] [bit] NOT NULL,
	[Numar_bon] [int] NOT NULL,
	[Data_bon] [datetime] NOT NULL,
	[Vinzator] [varchar](10) NOT NULL,
	[Factura] [varchar](20) NULL,
	[Data_facturii] [datetime] NULL,
	[Data_scadentei] [datetime] NULL,
	[Tert] [varchar](50) NULL,
	[Gestiune] [varchar](50) NULL,
	[Loc_de_munca] [varchar](50) NULL,
	[Persoana_de_contact] [varchar](50) NULL,
	[Punct_de_livrare] [varchar](50) NULL,
	[Categorie_de_pret] [smallint] NULL,
	[Contract] [varchar](8) NULL,
	[Comanda] [varchar](13) NULL,
	[Observatii] [varchar](2000) NULL,
	[Explicatii] [varchar](500) NULL,
	[UID] [varchar](36) NULL,
	[Bon] [xml] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[antetBonuri]') AND name = N'Numar_bon_Tip')
CREATE UNIQUE CLUSTERED INDEX [Numar_bon_Tip] ON [dbo].[antetBonuri] 
(
	[Data_bon] ASC,
	[Casa_de_marcat] ASC,
	[Vinzator] ASC,
	[Numar_bon] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[antetBonuri]') AND name = N'Tert')
CREATE NONCLUSTERED INDEX [Tert] ON [dbo].[antetBonuri] 
(
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[anexafac]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[anexafac]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[anexafac](
	[Subunitate] [char](9) NOT NULL,
	[Numar_factura] [char](20) NOT NULL,
	[Numele_delegatului] [char](30) NOT NULL,
	[Seria_buletin] [char](10) NOT NULL,
	[Numar_buletin] [char](10) NOT NULL,
	[Eliberat] [char](30) NOT NULL,
	[Mijloc_de_transport] [char](30) NOT NULL,
	[Numarul_mijlocului] [char](13) NOT NULL,
	[Data_expedierii] [datetime] NOT NULL,
	[Ora_expedierii] [char](6) NOT NULL,
	[Observatii] [char](200) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[anexafac]') AND name = N'Sub_Factura')
CREATE UNIQUE CLUSTERED INDEX [Sub_Factura] ON [dbo].[anexafac] 
(
	[Subunitate] ASC,
	[Numar_factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[doc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[doc](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Cod_gestiune] [char](9) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Cod_tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Contractul] [char](20) NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Gestiune_primitoare] [char](13) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Valoare] [float] NOT NULL,
	[Tva_11] [float] NOT NULL,
	[Tva_22] [float] NOT NULL,
	[Valoare_valuta] [float] NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Discount_p] [real] NOT NULL,
	[Discount_suma] [float] NOT NULL,
	[Pro_forma] [binary](1) NOT NULL,
	[Tip_miscare] [char](1) NOT NULL,
	[Numar_DVI] [char](30) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Jurnal] [char](3) NOT NULL,
	[Numar_pozitii] [int] NOT NULL,
	[Stare] [smallint] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[doc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Numar] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND name = N'Actualizare')
CREATE UNIQUE NONCLUSTERED INDEX [Actualizare] ON [dbo].[doc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Numar] ASC,
	[Jurnal] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND name = N'Facturare')
CREATE NONCLUSTERED INDEX [Facturare] ON [dbo].[doc] 
(
	[Subunitate] ASC,
	[Cod_tert] ASC,
	[Factura] ASC,
	[Tip] ASC,
	[Pro_forma] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND name = N'Numar')
CREATE NONCLUSTERED INDEX [Numar] ON [dbo].[doc] 
(
	[Numar] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[doc]') AND name = N'Punct_livrare')
CREATE NONCLUSTERED INDEX [Punct_livrare] ON [dbo].[doc] 
(
	[Subunitate] ASC,
	[Cod_tert] ASC,
	[Gestiune_primitoare] ASC,
	[Tip] ASC,
	[Numar] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[docAnalize]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[docAnalize]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[docAnalize](
	[Subunitate] [char](9) NOT NULL,
	[Tip_doc] [char](2) NOT NULL,
	[Nr_doc] [char](8) NOT NULL,
	[Data_doc] [datetime] NOT NULL,
	[Nr_poz_doc] [int] NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Gest] [char](9) NOT NULL,
	[Cod] [char](20) NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Factura] [char](8) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Mijloc_transp] [char](1) NOT NULL,
	[Nr_mijloc_transp] [char](20) NOT NULL,
	[Delegat] [char](20) NOT NULL,
	[Buletin] [char](13) NOT NULL,
	[Cant_fizica] [float] NOT NULL,
	[Tara_reala] [float] NOT NULL,
	[Cant_stoc] [float] NOT NULL,
	[Cant_utila] [float] NOT NULL,
	[Plata_la_util] [bit] NOT NULL,
	[Pret] [float] NOT NULL,
	[Tara_furn] [float] NOT NULL,
	[Cant_furn] [float] NOT NULL,
	[Nr_buletin] [char](18) NOT NULL,
	[Data_buletin] [datetime] NOT NULL,
	[Soi_FS] [real] NOT NULL,
	[Mh_furn] [float] NOT NULL,
	[Mh_doc] [float] NOT NULL,
	[Umid_furn] [float] NOT NULL,
	[Umid_doc] [float] NOT NULL,
	[Cs_furn] [float] NOT NULL,
	[Csa_doc] [float] NOT NULL,
	[Csn_doc] [float] NOT NULL,
	[Gl] [float] NOT NULL,
	[Ig] [float] NOT NULL,
	[Id] [float] NOT NULL,
	[Sticl] [float] NOT NULL,
	[Ic] [float] NOT NULL,
	[Ind1] [float] NOT NULL,
	[Ind2] [float] NOT NULL,
	[Ind3] [float] NOT NULL,
	[Ind4] [float] NOT NULL,
	[Ind5] [float] NOT NULL,
	[Culoare] [char](25) NOT NULL,
	[Infestare] [char](25) NOT NULL,
	[Miros] [char](25) NOT NULL,
	[Mh_decontare] [float] NOT NULL,
	[Umid_decontare] [float] NOT NULL,
	[Cs_decontare] [float] NOT NULL,
	[Ind1_decontare] [float] NOT NULL,
	[Ind2_decontare] [float] NOT NULL,
	[Ind3_decontare] [float] NOT NULL,
	[Ora_intrarii] [char](6) NOT NULL,
	[Ora_iesirii] [char](6) NOT NULL,
	[Tip_misc] [char](20) NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Jurnal] [char](20) NOT NULL,
	[Csv_decontare] [float] NOT NULL,
	[Taxa_uscare] [float] NOT NULL,
	[Usc_fact] [char](13) NOT NULL,
	[Cantitate1] [float] NOT NULL,
	[Cantitate2] [float] NOT NULL,
	[Termen_livrare] [datetime] NOT NULL,
	[Rez3] [char](20) NOT NULL,
	[Datorie_rec] [float] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[docAnalize]') AND name = N'Analize1')
CREATE UNIQUE CLUSTERED INDEX [Analize1] ON [dbo].[docAnalize] 
(
	[Subunitate] ASC,
	[Tip_doc] ASC,
	[Nr_doc] ASC,
	[Data_doc] ASC,
	[Nr_poz_doc] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[docAnalize]') AND name = N'Analize2')
CREATE UNIQUE NONCLUSTERED INDEX [Analize2] ON [dbo].[docAnalize] 
(
	[Subunitate] ASC,
	[Tip_doc] ASC,
	[Data_buletin] ASC,
	[Nr_buletin] ASC,
	[Nr_poz_doc] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[docAnalize]') AND name = N'Analize4')
CREATE NONCLUSTERED INDEX [Analize4] ON [dbo].[docAnalize] 
(
	[Subunitate] ASC,
	[Gest] ASC,
	[Cod] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[docAnalize]') AND name = N'Analize5')
CREATE NONCLUSTERED INDEX [Analize5] ON [dbo].[docAnalize] 
(
	[Subunitate] ASC,
	[Loc_munca] ASC,
	[Cod] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [plinefect]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plinefect]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[plinefect] on [dbo].[pozplin] for update,insert,delete as
begin
    insert into efecte (Subunitate,Tip,Tert,Nr_efect,Cont,Data,Data_scadentei,Valoare,Valuta,Curs,Valoare_valuta,Decontat,
    Sold,Decontat_valuta,Sold_valuta,Loc_de_munca,Comanda,Data_decontarii,Explicatii)
	select a.subunitate, (case a.plata_incasare when ''IS'' then ''P'' when ''PS'' then ''I'' else left(a.plata_incasare,1) end), 
	(case when a.tert='''' then a.cont_dif else a.tert end), max(isnull(b.decont, a.numar)),
    (case when isnull(c1.sold_credit, 0)=8 then a.cont else a.cont_corespondent end), 
	max(a.data), max(a.data), 0, max(a.valuta),
    max(a.curs),0,0,0,0,0, max(a.loc_de_munca), '''', 
	max(case when isnull(c2.sold_credit, 0)=8 then a.data else convert(datetime,''01/01/1901'') end), left(max(a.explicatii),30) 
    from inserted a 
	left outer join extpozplin b on a.subunitate=b.subunitate and a.cont=b.cont and a.data=b.data and a.numar=b.numar and a.numar_pozitie=b.numar_pozitie
	left outer join conturi c1 on c1.subunitate=a.subunitate and c1.cont=a.cont
	left outer join conturi c2 on c2.subunitate=a.subunitate and c2.cont=a.cont_corespondent
    where (isnull(c1.sold_credit, 0)=8 or isnull(c2.sold_credit, 0)=8) 
    and not exists (select 1 from efecte e where e.subunitate=a.subunitate and e.tip=(case a.plata_incasare when ''IS'' then ''P'' when ''PS'' then ''I'' else left(a.plata_incasare,1) end) and e.tert=(case when a.tert='''' then a.cont_dif else a.tert end) and e.nr_efect=isnull(b.decont, a.numar))
group by a.subunitate, a.plata_incasare, (case when a.tert='''' then a.cont_dif else a.tert end), isnull(b.decont, a.numar), 
(case when isnull(c1.sold_credit, 0)=8 then a.cont else a.cont_corespondent end)

declare @valoare float,@valoarev float,@decontat float,@decontatv float,@datadec datetime,@datascad datetime
declare @csub char(9),@ctip char(2),@ctert char(13),@cnr char(13),@semn int,@suma float,
             @sumadec float,@sumadif float,@valuta char(3),@curs float,@ddata datetime,@ddatasc datetime,@sumaachv float
declare @gsub char(9), @gtip char(1), @gtert char(13),@gnr char(13),@gfetch int

declare tmp cursor for
select subunitate, plata_incasare, tert, isnull((select decont from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),numar) as numar,1,(case when plata_incasare in (''IS'',''PS'') then -1 else 1 end)*suma,0,0, valuta,curs,data,achit_fact, isnull((select data_scadentei from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),data)
from inserted where (inserted.cont in (select cont from conturi where subunitate=inserted.subunitate and sold_credit=8)) 
union all
select subunitate, plata_incasare, (case when tert='''' then cont_dif else tert end),isnull((select decont from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),numar) as numar,1,0,(case when plata_incasare in (''IS'',''PS'') then -1 else 1 end)*suma,suma_dif, valuta,curs,data,0, isnull((select data_scadentei from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),data)
from inserted where (inserted.cont_corespondent in (select cont from conturi where subunitate=inserted.subunitate and sold_credit=8)) 
union all
select subunitate, plata_incasare, tert,isnull((select decont from extpozplin b where deleted.subunitate=b.subunitate and deleted.cont=b.cont and deleted.data=b.data and deleted.numar=b.numar and deleted.numar_pozitie=b.numar_pozitie),numar) as numar,-1, (case when plata_incasare in (''IS'',''PS'') then -1 else 1 end)*suma,0,0, valuta,curs,data,achit_fact, data 
from deleted where (deleted.cont in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=8)) 
union all
select subunitate, plata_incasare, (case when tert='''' then cont_dif else tert end),isnull((select decont from extpozplin b where deleted.subunitate=b.subunitate and deleted.cont=b.cont and deleted.data=b.data and deleted.numar=b.numar and deleted.numar_pozitie=b.numar_pozitie),numar) as numar,-1,0,(case when plata_incasare in (''IS'',''PS'') then -1 else 1 end)*suma,suma_dif, valuta,curs,data,0, data 
from deleted where (deleted.cont_corespondent in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=8)) 
order by subunitate, plata_incasare, tert, numar

open tmp
fetch next from tmp into @csub,@ctip,@ctert, @cnr, @semn,@suma,@sumadec,@sumadif,@valuta,@curs,@ddata,@sumaachv,@ddatasc
set @gsub=@csub
set @gtip=(case @ctip when ''IS'' then ''P'' when ''PS'' then ''I'' else left(@ctip,1) end)
set @gtert=@ctert
set @gnr=@cnr
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @Decontat=0
	set @Decontatv=0
	set @Datadec=''''
	set @Datascad=''''
	while @gsub=@csub and @gtip=(case @ctip when ''IS'' then ''P'' when ''PS'' then ''I'' else left(@ctip,1) end) and @gtert=@ctert and @gnr=@cnr and @gfetch=0
	begin
		set @valoare=@valoare+(@suma-@sumadif)*@semn
		set @decontat=@decontat+@sumadec*@semn
		if @valuta<>'''' set @valoarev=@valoarev+@sumaachv*@semn
		if @valuta<>'''' set @decontatv=@decontatv+@sumaachv*@semn
		if @semn=1 and @ctip<>''PF'' and @ctip<>''IB'' set @datadec=@ddata
		if @semn=1 set @datascad=@ddatasc 
		fetch next from tmp into @csub,@ctip, @ctert, @cnr, @semn,@suma,                                                                       @sumadec,@sumadif,@valuta,@curs,@ddata,@sumaachv,@ddatasc
		set @gfetch=@@fetch_status
	end
	update efecte set valoare=valoare+@valoare, decontat=decontat+@decontat, sold=sold+@valoare-@decontat,
		valoare_valuta=valoare_valuta+@valoarev, data_decontarii=@datadec, 
		data_scadentei=(case when @datascad='''' then data_scadentei else @datascad end), 
		decontat_valuta=decontat_valuta+@decontatv, sold_valuta=sold_valuta+@valoarev-@decontatv 
		where subunitate=@gsub and tip=@gtip and tert=@gtert and nr_efect=@gnr
	/*delete from efecte where subunitate=@gsub and tip=@gtip and tert=@gtert and nr_efect=@gnr 
		and valoare=0 and decontat=0 and valoare_valuta=0 and decontat_valuta=0*/
	set @gtert=@ctert
	set @gsub=@csub
	set @gnr=@cnr
	set @gtip=(case @ctip when ''IS'' then ''P'' when ''PS'' then ''I'' else left(@ctip,1) end)
end

close tmp
deallocate tmp
end
'
GO
/****** Object:  Table [dbo].[pdgrup]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pdgrup]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[pdgrup](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Cod] [char](20) NOT NULL,
	[Cod_intrare] [char](13) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret_de_stoc] [float] NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Grupa] [char](13) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pdgrup]') AND name = N'Unic')
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [dbo].[pdgrup] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Gestiune] ASC,
	[Cod] ASC,
	[Cod_intrare] ASC,
	[Numar_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pdgrup]') AND name = N'Factura')
CREATE NONCLUSTERED INDEX [Factura] ON [dbo].[pdgrup] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Factura] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [plindec]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plindec]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[plindec] on [dbo].[pozplin] for update,insert,delete with append as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @decrest1 int, @decrest2 int, @decmarct int
	set @decrest1=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DECREST''),0)-1
	set @decrest2=@decrest1+1
	set @decmarct=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DECMARCT''),0)
-------------
insert into deconturi select a.subunitate,''T'', left(cont_dif,6), (case when @decmarct=0 then isnull(decont, a.numar) else a.cont end), a.cont, max(a.data), max(a.data), 0, max(valuta), max(curs), 0,0,0,0,0, max(loc_de_munca), max(comanda), max(a.data), left(max(explicatii),30) 
from inserted a 
left outer join extpozplin b on a.subunitate=b.subunitate and a.cont=b.cont and a.data=b.data and a.numar=b.numar 
and a.numar_pozitie=b.numar_pozitie 
where a.cont in (select cont from conturi where subunitate=a.subunitate and sold_credit=9) 
and (case when @decmarct=0 then isnull(b.decont, a.numar) else a.cont end) not in (select decont from deconturi where subunitate=a.subunitate and marca=left(a.cont_dif,6) and tip=''T'')
    group by a.subunitate,a.cont_dif,isnull(b.decont, a.numar),a.cont,a.cont_corespondent

insert into deconturi select a.subunitate,''T'', left(cont_dif,6), (case when @decmarct=0 then isnull(decont, a.numar) else a.cont_corespondent end), a.cont_corespondent, max(a.data),max(a.data),0,max(valuta),max(curs),0,0,0,0,0, max(loc_de_munca), max(comanda),max(a.data), left(max(explicatii),30) 
from inserted a 
left outer join extpozplin b on a.subunitate=b.subunitate and a.cont=b.cont and a.data=b.data and a.numar=b.numar 
and a.numar_pozitie=b.numar_pozitie 
where a.cont_corespondent in (select cont from conturi where subunitate=a.subunitate and sold_credit=9) 
and (case when @decmarct=0 then isnull(b.decont, a.numar) else a.cont_corespondent end) not in (select decont from deconturi where subunitate=a.subunitate and marca=left(a.cont_dif,6) and tip=''T'')
    group by a.subunitate,a.cont_dif,isnull(b.decont, a.numar),a.cont,a.cont_corespondent

declare @valoare float,@valoarev float,@decontat float,@decontatv float,@datadec datetime, @datascad datetime, @lm char(9), @com char(40), @ex char(30)
declare @csub char(9),@ctip char(2),@cmarca char(6),@cdecont char(13),@semn int,@suma float,@sumav float,@sumadec float,@sumadecv float,@valuta char(3),@curs float,@ddata datetime, @ddatascad datetime, @sumarestv float, @glm char(9), @gcom char(40), @gex char(30)
declare @gsub char(9),@gmarca char(6),@gdecont char(13),@gfetch int

declare tmp cursor for
select subunitate,plata_incasare,left(cont_dif,6) as marca, (case when @decmarct=0 then isnull((select decont from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),numar) else cont end) as dec,1,0,0,suma,suma_valuta,valuta,curs,data, data, achit_fact, loc_de_munca,comanda, left(explicatii,30)
from inserted where cont in (select cont from conturi where subunitate=inserted.subunitate and sold_credit=9) 
union all 
select subunitate,plata_incasare,left(cont_dif,6), (case when @decmarct=0 then isnull((select decont from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),numar) else cont_corespondent end), 1,suma,suma_valuta, 0,0, valuta,curs,data,isnull((select data_scadentei from extpozplin b where inserted.subunitate=b.subunitate and inserted.cont=b.cont and inserted.data=b.data and inserted.numar=b.numar and inserted.numar_pozitie=b.numar_pozitie),data),0,  loc_de_munca,comanda, left(explicatii,30)
from inserted where cont_corespondent in (select cont from conturi where subunitate=inserted.subunitate and sold_credit=9) 
union all 
select subunitate,plata_incasare,left(cont_dif,6), (case when @decmarct=0 then isnull((select decont from extpozplin b where deleted.subunitate=b.subunitate and deleted.cont=b.cont and deleted.data=b.data and deleted.numar=b.numar and deleted.numar_pozitie=b.numar_pozitie),numar) else cont end),-1,0,0,suma,suma_valuta,valuta,curs,data,data,achit_fact,  loc_de_munca,comanda, left(explicatii,30) 
from deleted where cont in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=9) 
union all 
select subunitate,plata_incasare,left(cont_dif,6), (case when @decmarct=0 then isnull((select decont from extpozplin b where deleted.subunitate=b.subunitate and deleted.cont=b.cont and deleted.data=b.data and deleted.numar=b.numar and deleted.numar_pozitie=b.numar_pozitie),numar) else cont_corespondent end),-1,suma,suma_valuta,0,0,valuta,curs,data,data,0,  loc_de_munca,comanda, left(explicatii,30) 
from deleted where cont_corespondent in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=9) 
order by subunitate,marca,dec

open tmp
fetch next from tmp into @csub,@ctip,@cmarca,@cdecont,@semn,@suma,@sumav,@sumadec,@sumadecv, @valuta,@curs,@ddata,@ddatascad, @sumarestv, @lm, @com, @ex
set @gsub=@csub
set @gmarca=@cmarca
set @gdecont=@cdecont
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @Decontat=0
	set @Decontatv=0
	set @Datadec=''''
	set @Datascad=''''
	set @glm=''''
	set @gcom=''''
	set @gex=''''
	while @gsub=@csub and @gmarca=@cmarca and @gdecont=@cdecont and @gfetch=0
	begin
		set @valoare=@valoare+@suma*@semn*(case when @ctip=''ID'' then @decrest1 else 1 end)
			+(case when left(@ctip,1)=''I'' then @sumadec*@semn else 0 end)
		set @decontat=@decontat
			+@sumadec*@semn*(case when left(@ctip,1)=''P'' then 1 else 0 end)
			+@suma*@semn*(case when @ctip=''ID'' then @decrest2 else 0 end)
		if @valuta<>'''' 
			set @valoarev=@valoarev+(case when @ctip=''ID'' then @decrest1 else 1 end)*@sumav*@semn
			+(case when left(@ctip,1)=''I'' then @decontatv*@semn else 0 end)
		if @valuta<>'''' 
			set @decontatv=@decontatv
			+@sumarestv*@semn*(case when left(@ctip,1)=''P'' then 1 else 0 end)
			+@sumav*@semn*(case when @ctip=''ID'' then @decrest2 else 0 end)
		if @semn=1 and @suma=0 and @sumav=0 set @datadec=@ddata
		if @semn=1 and not(@suma=0 and @sumav=0) set @datascad=@ddatascad
		if @semn=1 and not(@suma=0 and @sumav=0) set @glm=@lm
		if @semn=1 and not(@suma=0 and @sumav=0) set @gcom=@com
		if @semn=1 and not(@suma=0 and @sumav=0) set @gex=@ex
		fetch next from tmp into @csub,@ctip,@cmarca,@cdecont,@semn,@suma,@sumav,@sumadec, 
			@sumadecv,@valuta,@curs,@ddata,@ddatascad,@sumarestv, @lm, @com, @ex
		set @gfetch=@@fetch_status
	end
	update deconturi set valoare=valoare+@valoare, decontat=decontat+@decontat, sold=sold+@valoare-@decontat,
		data_ultimei_decontari=(case when @datadec='''' then data_ultimei_decontari else @datadec end), 
		valoare_valuta=valoare_valuta+@valoarev, 
		data_scadentei=(case when @datascad='''' then data_scadentei else @datascad end),
		decontat_valuta=decontat_valuta+@decontatv, sold_valuta=sold_valuta+@valoarev-@decontatv, 
		loc_de_munca=(case when @glm='''' then loc_de_munca else @glm end),
		comanda=(case when @gcom='''' then comanda else @gcom end),
		explicatii=(case when @gex='''' then explicatii else @gex end)
	where subunitate=@gsub and tip=''T'' and marca=@gmarca and decont=@gdecont
	/*delete from deconturi where subunitate=@gsub and tip=''T'' and marca=@gmarca and decont=@gdecont 
		and valoare=0 and decontat=0 and valoare_valuta=0 and decontat_valuta=0*/
	set @gmarca=@cmarca
	set @gsub=@csub
	set @gdecont=@cdecont
end

close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [plinantet]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plinantet]'))
EXEC dbo.sp_executesql @statement = N'--***
/*Pentru creat antet plati / incasari*/
create trigger [dbo].[plinantet] on [dbo].[pozplin] for update,insert,delete with append as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @docdef int
	set @docdef=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCDEF''),0)
-------------
declare @decgrluna int
set @decgrluna = isnull((select val_logica from par where tip_parametru=''GE'' and parametru=''DECONTCT9''), 0)

insert into plin (Subunitate,Cont,Data,Numar,Valuta,Curs,Total_plati,Total_incasari,Ziua,Numar_pozitii,Jurnal,stare)
	select inserted.subunitate,inserted.cont,(case when @decgrluna=1 and max(conturi.sold_credit)=''9'' then dbo.eom(data) else data end),
	'''',max(valuta),max(curs),0,0,max(day (data)),0,
	jurnal, (case when @docdef=1 and right(max(utilizator),1)=''2'' then 2 else 0 end) 
         from inserted,conturi 
	where inserted.cont=conturi.cont and inserted.subunitate=conturi.subunitate 
	and inserted.cont not in (select cont from plin where subunitate=inserted.subunitate and 
	data=(case when @decgrluna=1 and conturi.sold_credit=''9'' then dbo.eom(inserted.data) else inserted.data end) and jurnal=inserted.jurnal) 
	group by inserted.subunitate,inserted.cont,data,jurnal

/*Pentru calculul valorilor*/
declare @total_plati float, @total_incasari float, @numar_poz int
declare @csub char(9),@ctip char(2),@ccont char(13),@cdata datetime,@cjurnal char (3),@semn int,@suma float
declare @gsub char(9),@gcont char(13),@gdata datetime,@gjurnal char (3),@gfetch int

declare tmp cursor for
select subunitate,plata_incasare,cont,data,jurnal,1,suma 
	from inserted union all
select subunitate,plata_incasare,cont,data,jurnal,-1,suma
	from deleted 
order by subunitate,cont,data,jurnal,plata_incasare

open tmp
fetch next from tmp into @csub,@ctip,@ccont,@cdata,@cjurnal,@semn,@suma
set @gsub=@csub
set @gcont=@ccont
set @gdata=@cdata
set @gjurnal=@cjurnal
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @total_plati=0
	set @total_incasari=0
	set @numar_poz=0
	while @gsub=@csub and @gcont=@ccont and @gdata=@cdata and @gjurnal=@cjurnal and @gfetch=0
	begin
		set @numar_poz=@numar_poz+@semn
		if left(@ctip,1)=''P'' 
			set @total_plati=@total_plati+@semn*@suma
		if left(@ctip,1)=''I''
			set @total_incasari=@total_incasari+@semn*@suma
		fetch next from tmp into @csub,@ctip,@ccont,@cdata,@cjurnal,@semn,@suma
		set @gfetch=@@fetch_status
	end
	update plin set total_plati=total_plati+@total_plati, 
		total_incasari=total_incasari+@total_incasari,
		numar_pozitii=numar_pozitii+@numar_poz 
		where plin.subunitate=@gsub and plin.cont=@gcont and plin.data=@gdata and plin.jurnal=@gjurnal

	delete from plin where subunitate = @gsub and data = @gdata and cont=@gcont
			and total_incasari=0 and total_plati = 0 and numar_pozitii = 0
	set @gsub=@csub
	set @gcont=@ccont
	set @gdata=@cdata
	set @gjurnal=@cjurnal
end

close tmp
deallocate tmp
end'
GO
/****** Object:  Table [dbo].[incfact]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[incfact]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[incfact](
	[Subunitate] [char](9) NOT NULL,
	[Numar_factura] [char](20) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Mod_plata] [char](1) NOT NULL,
	[Serie_doc] [char](5) NOT NULL,
	[Nr_doc] [char](20) NOT NULL,
	[data_doc] [datetime] NOT NULL,
	[suma_doc] [float] NOT NULL,
	[datasc_doc] [datetime] NOT NULL,
	[mod_tp] [char](1) NOT NULL,
	[info_tp] [char](50) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Loc_de_munca] [char](13) NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[incfact]') AND name = N'Unic')
CREATE UNIQUE CLUSTERED INDEX [Unic] ON [dbo].[incfact] 
(
	[Subunitate] ASC,
	[Numar_factura] ASC,
	[Numar_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[incfact]') AND name = N'Numar')
CREATE NONCLUSTERED INDEX [Numar] ON [dbo].[incfact] 
(
	[Subunitate] ASC,
	[Mod_plata] ASC,
	[Nr_doc] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [incplin]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[incplin]'))
EXEC dbo.sp_executesql @statement = N'--***
CREATE TRIGGER [dbo].[incplin] ON [dbo].[incfact] FOR DELETE, INSERT, UPDATE NOT FOR REPLICATION AS
begin
-------------	din tabela par (parametri trimis de Magic):
	--	[Trim (FX)], [Trim (FZ)], GA, FY, [Trim (GS)], HI, [Trim (GU)], GT, GV
	declare @incnumf_a varchar(13), @credcard_a varchar(13), @credcard_n int, @incnumf_n int, @incefecte_a varchar(13), @incnumini int,
		@incec_a varchar(13), @incefecte_n int, @incec_n int
	set @incnumf_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''INCNUMF''),''''))
	set @credcard_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CREDCARD''),''''))
	set @credcard_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''CREDCARD''),0)
	set @incnumf_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''INCNUMF''),0)
	set @incefecte_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''INCEFECTE''),''''))
	set @incnumini=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''INCNUMINI''),0)
	set @incec_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''INCCEC''),''''))
	set @incefecte_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''INCEFECTE''),0)
	set @incec_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''INCCEC''),0)
-------------
SELECT DISTINCT A.Subunitate, 
(case when a.mod_plata=''F'' then @incefecte_a+(case when @incefecte_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) when a.mod_plata=''C'' then @incec_a+(case when @incec_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) when a.mod_plata=''K'' then @credcard_a+(case when @credcard_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) when a.mod_plata=''N'' and @incnumini=1 or a.mod_plata=''V'' then a.loc_de_munca else @incnumf_a+(case when @incnumf_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) end) as cont, 
a.Data_doc as data, rtrim(a.nr_doc) as numar, ''IB'' as plata_incasare, a.Tert, a.numar_Factura as factura, 
a.cont as cont_corespondent, left(''INC.FACT.''+a.mod_plata+'' - ''+rtrim(c.denumire), 50) as explicatii, b.Loc_de_munca, 
(case when 1=0 and a.mod_plata in (''K'', ''C'', ''F'') then convert(char(10), a.datasc_doc, 102) else b.comanda end) as comanda, 
a.Utilizator, a.Data_operarii, a.ora_operarii, identity(int, 1, 1) as numar_pozitie, a.Jurnal, a.datasc_doc as data_scad,
(case when a.mod_plata = ''C'' then a.serie_doc else '''' end) as serie, (case when a.mod_plata = ''C'' then a.nr_doc else '''' end) as numarCEC,
(case when a.mod_plata = ''C'' then ltrim(left(a.info_tp,25)) else '''' end) as bancaTERT, (case when a.mod_plata = ''C'' then ltrim(substring(a.info_tp,26,25)) else '''' end) as contTERT
into #incplin
FROM INSERTED A, facturi b, terti c 
WHERE a.tert=c.tert and a.tert=b.tert and a.numar_factura=b.factura and b.tip=0x46 and 
A.MOD_PLATA in (''N'', ''V'', ''K'', ''F'', ''C'') and a.suma_doc<>0 
and not exists (select numar from pozplin where subunitate=a.subunitate 
	and cont=(case when a.mod_plata=''F'' then @incefecte_a+(case when @incefecte_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) when a.mod_plata=''C'' then @incec_a+(case when @incec_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) when a.mod_plata=''K'' then @credcard_a+(case when @credcard_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) when a.mod_plata=''N'' and @incnumini=1 or a.mod_plata=''V'' then a.loc_de_munca else @incnumf_a+(case when @incnumf_n=1 then ''.''+rtrim(a.loc_de_munca) else '''' end) end) 
	and plata_incasare=''IB'' and data=a.data_doc and numar=a.nr_doc)

declare @NrPoz int, @Pozitii int
set @Pozitii = (select count(*) from #incplin)
set @NrPoz = isnull((select max(val_numerica) from par where tip_parametru=''DO'' and parametru=''POZITIE''), 0)
if @NrPoz+@Pozitii > 999999999 set @NrPoz = 0
update par set val_numerica=@NrPoz+@Pozitii where tip_parametru=''DO'' and parametru=''POZITIE''

INSERT INTO POZPLIN (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, 
Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
Cont_dif, Suma_dif, Achit_fact, Jurnal)
SELECT Subunitate, cont, data, numar, plata_incasare, tert, factura, 
cont_corespondent, 0, '''', 0, 0, 0, 0, 0, 
explicatii, loc_de_munca, comanda, Utilizator, Data_operarii, Ora_operarii, @NrPoz+numar_pozitie, 
'''', 0, 0, Jurnal
from #incplin

INSERT INTO EXTPOZPLIN (Subunitate, Cont, Data, Numar, 
Numar_pozitie, Tip, Cont_corespondent, Marca, Decont, Data_scadentei, 
Suma, Suma_achitat, Banca, Cont_in_banca, Numar_justificare, Data_document, Serie_CEC, Numar_CEC, Banca_tert, Cont_in_banca_tert, Jurnal)
SELECT Subunitate, cont, data, numar, 
@NrPoz+numar_pozitie, plata_incasare, cont_corespondent, Tert, numar, data_scad, 
0, 0, '''', '''', '''', data, serie, numarCEC, bancaTERT, contTERT, a.jurnal 
FROM #incplin a
WHERE not exists (select numar from extpozplin where subunitate=a.subunitate and cont=a.cont and tip=a.plata_incasare and data=a.data and numar=a.numar)

drop table #incplin

declare @valoare float, @valoare_valuta float, @gfetch int, @glocm char(13), @gcont char(13), @gmodpl char(1), 
	@csub char(9), @cnumar char(9), @ctert char(13), @cfactura char(20), @suma float, @ddata datetime, @ddatasc datetime, @semn int, @valuta char(3), @curs float, 
	@gsub char(9), @gtert char(13), @gfactura char(20), @gnumar char(9), @gdata datetime, @gvaluta char(3), @gcurs float,
	@modpl char(1), @locm char(13), @gdatasc datetime

declare tmpx cursor for
select subunitate, mod_plata, nr_doc, data_doc, tert, numar_factura, 1, suma_doc, 
loc_de_munca, datasc_doc,
rtrim(case when mod_plata=''V'' then left(info_tp, 3) else '''' end) as valuta_doc, 
(case when mod_plata=''V'' and isnumeric(substring(info_tp, 4, 11))=1 then convert(float, substring(info_tp, 4, 11)) else 0 end) as curs_doc
from inserted where mod_plata in (''N'', ''V'', ''K'', ''F'', ''C'') 
union all 
select subunitate, mod_plata, nr_doc, data_doc, tert, numar_factura, -1, suma_doc, 
loc_de_munca, datasc_doc,
rtrim(case when mod_plata=''V'' then left(info_tp, 3) else '''' end), 
(case when mod_plata=''V'' and isnumeric(substring(info_tp, 4, 11))=1 then convert(float, substring(info_tp, 4, 11)) else 0 end)
from deleted where mod_plata in (''N'', ''V'', ''K'', ''F'', ''C'') 
order by subunitate, mod_plata, nr_doc, data_doc, tert, numar_factura, valuta_doc, curs_doc

open tmpx
fetch next from tmpx into @csub, @modpl, @cnumar, @ddata, @ctert, @cfactura, @semn, @suma, @locm, @ddatasc, @valuta, @curs
set @gsub=@csub
set @gmodpl=@modpl
set @gnumar=@cnumar
set @gdata=@ddata
set @gvaluta=@valuta
set @gcurs=@curs
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @valoare=0
	set @valoare_valuta=0
	set @gtert=@ctert
	set @gfactura=@cfactura
	set @glocm=@locm
	set @gdatasc=@ddatasc
	while @gsub=@csub and @gmodpl=@modpl and @gnumar=@cnumar and @gdata=@ddata and @gvaluta=@valuta and @gcurs=@curs and @gfetch=0
	begin
		set @valoare=@valoare+@semn*(case when @modpl=''V'' then round(convert(decimal(18,5), @suma*@curs), 2) else @suma end)
		if @valuta<>'''' and @curs<>0
			set @valoare_valuta=@valoare_valuta+@semn*@suma
		if @semn=1 set @gtert=@ctert
		if @semn=1 set @gfactura=@cfactura
		if @semn=1 set @glocm=@locm
		if @semn=1 set @gdatasc=@ddatasc
		fetch next from tmpx into @csub, @modpl, @cnumar, @ddata, @ctert, @cfactura, @semn, @suma, @locm, @ddatasc, @valuta, @curs
		set @gfetch=@@fetch_status
	end
	update pozplin 
	set suma=suma+@valoare, tert=@gtert, factura=@gfactura, 
	valuta=@gvaluta, curs=@gcurs, suma_valuta=@valoare_valuta,
	Curs_la_valuta_facturii=@gcurs, achit_fact=@valoare_valuta
	where subunitate=@gsub and data=@gdata  and plata_incasare=''IB'' and numar=@gnumar
	and cont=(case when @gmodpl=''F'' then @incefecte_a+(case when @incefecte_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''C'' then @incec_a+(case when @incec_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''K'' then @credcard_a+(case when @credcard_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''N'' and @incnumini=1 or @gmodpl=''V'' then @glocm else @incnumf_a+(case when @incnumf_n=1 then ''.''+rtrim(@glocm) else '''' end) end) 
		
	update extpozplin 
	set data_scadentei=@gdatasc
	from pozplin p
	where extpozplin.subunitate=p.subunitate and extpozplin.cont=p.cont and extpozplin.data=p.data 
	and extpozplin.numar=p.numar and extpozplin.numar_pozitie=p.numar_pozitie 
	and p.subunitate=@gsub and p.data=@gdata and p.plata_incasare=''IB'' and p.numar=@gnumar
	and p.cont=(case when @gmodpl=''F'' then @incefecte_a+(case when @incefecte_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''C'' then @incec_a+(case when @incec_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''K'' then @credcard_a+(case when @credcard_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''N'' and @incnumini=1 or @gmodpl=''V'' then @glocm else @incnumf_a+(case when @incnumf_n=1 then ''.''+rtrim(@glocm) else '''' end) end) 

	delete from pozplin  
	where subunitate=@gsub and data=@gdata  and plata_incasare=''IB'' and numar=@gnumar and suma=0
	and cont=(case when @gmodpl=''F'' then @incefecte_a+(case when @incefecte_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''C'' then @incec_a+(case when @incec_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''K'' then @credcard_a+(case when @credcard_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''N'' and @incnumini=1 or @gmodpl=''V'' then @glocm else @incnumf_a+(case when @incnumf_n=1 then ''.''+rtrim(@glocm) else '''' end) end) 
	
	delete from extpozplin 
	where subunitate=@gsub and data=@gdata and numar=@gnumar 
	and cont=(case when @gmodpl=''F'' then @incefecte_a+(case when @incefecte_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''C'' then @incec_a+(case when @incec_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''K'' then @credcard_a+(case when @credcard_n=1 then ''.''+rtrim(@glocm) else '''' end) when @gmodpl=''N'' and @incnumini=1 or @gmodpl=''V'' then @glocm else @incnumf_a+(case when @incnumf_n=1 then ''.''+rtrim(@glocm) else '''' end) end) 
	and not exists (select 1 from pozplin p where extpozplin.subunitate=p.subunitate and extpozplin.cont=p.cont and extpozplin.data=p.data and extpozplin.numar=p.numar and extpozplin.numar_pozitie=p.numar_pozitie)

	set @gsub=@csub
	set @gmodpl=@modpl
	set @gnumar=@cnumar
	set @gdata=@ddata
	set @gvaluta=@valuta
	set @gcurs=@curs
end
close tmpx
deallocate tmpx
end
'
GO
/****** Object:  Table [dbo].[mismf_nu_sterge]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mismf_nu_sterge]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[mismf_nu_sterge](
	[Subunitate] [char](9) NOT NULL,
	[Data_lunii_de_miscare] [datetime] NOT NULL,
	[Numar_de_inventar] [char](13) NOT NULL,
	[Tip_miscare] [char](3) NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Data_miscarii] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Pret] [float] NOT NULL,
	[TVA] [float] NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[Loc_de_munca_primitor] [char](13) NOT NULL,
	[Gestiune_primitoare] [char](13) NOT NULL,
	[Diferenta_de_valoare] [float] NOT NULL,
	[Data_sfarsit_conservare] [datetime] NOT NULL,
	[Subunitate_primitoare] [char](40) NOT NULL,
	[Procent_inchiriere] [real] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[misMF]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[misMF]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[misMF](
	[Subunitate] [char](9) NOT NULL,
	[Data_lunii_de_miscare] [datetime] NOT NULL,
	[Numar_de_inventar] [char](13) NOT NULL,
	[Tip_miscare] [char](3) NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Data_miscarii] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Pret] [float] NOT NULL,
	[TVA] [float] NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[Loc_de_munca_primitor] [char](13) NOT NULL,
	[Gestiune_primitoare] [char](13) NOT NULL,
	[Diferenta_de_valoare] [float] NOT NULL,
	[Data_sfarsit_conservare] [datetime] NOT NULL,
	[Subunitate_primitoare] [char](40) NOT NULL,
	[Procent_inchiriere] [real] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[misMF]') AND name = N'Actualizare')
CREATE UNIQUE CLUSTERED INDEX [Actualizare] ON [dbo].[misMF] 
(
	[Subunitate] ASC,
	[Data_lunii_de_miscare] ASC,
	[Tip_miscare] ASC,
	[Numar_de_inventar] ASC,
	[Numar_document] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[misMF]') AND name = N'Pentru_calcul')
CREATE NONCLUSTERED INDEX [Pentru_calcul] ON [dbo].[misMF] 
(
	[Subunitate] ASC,
	[Data_lunii_de_miscare] ASC,
	[Numar_de_inventar] ASC,
	[Tip_miscare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pvbon]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pvbon]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[pvbon](
	[Casa_de_marcat] [smallint] NOT NULL,
	[Chitanta] [bit] NOT NULL,
	[Numar_bon] [int] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Agent] [char](9) NOT NULL,
	[Punct_de_livrare] [char](5) NOT NULL,
	[Categorie_de_pret] [smallint] NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Contract] [char](8) NOT NULL,
	[Explicatii] [char](30) NOT NULL,
	[Valoare] [float] NOT NULL,
	[Comanda] [char](13) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[prog_plin]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[prog_plin]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[prog_plin](
	[Tip] [char](1) NOT NULL,
	[Element] [char](1) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Suma] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Suma_valuta] [float] NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Bifat] [bit] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[prog_plin]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[prog_plin] 
(
	[Tip] ASC,
	[Element] ASC,
	[Data] ASC,
	[Tert] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[prog_plin]') AND name = N'Data')
CREATE UNIQUE NONCLUSTERED INDEX [Data] ON [dbo].[prog_plin] 
(
	[Data] ASC,
	[Element] DESC,
	[Tip] ASC,
	[Tert] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[prog_plin]') AND name = N'Tert')
CREATE NONCLUSTERED INDEX [Tert] ON [dbo].[prog_plin] 
(
	[Tip] ASC,
	[Element] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PozBord]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PozBord]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PozBord](
	[Subunitate] [char](9) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Suma] [float] NOT NULL,
	[Stare] [char](1) NOT NULL,
	[Explicatii] [char](50) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[PozBord]') AND name = N'Unic')
CREATE UNIQUE NONCLUSTERED INDEX [Unic] ON [dbo].[PozBord] 
(
	[Subunitate] ASC,
	[Numar] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[istfact]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[istfact]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[istfact](
	[Data_an] [datetime] NOT NULL,
	[Subunitate] [char](9) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Tip] [char](1) NOT NULL,
	[Factura] [char](20) NOT NULL,
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
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[istfact]') AND name = N'Ist_fact')
CREATE UNIQUE CLUSTERED INDEX [Ist_fact] ON [dbo].[istfact] 
(
	[Data_an] ASC,
	[Subunitate] ASC,
	[Tip] ASC,
	[Factura] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[istfact]') AND name = N'Factura')
CREATE NONCLUSTERED INDEX [Factura] ON [dbo].[istfact] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[istfact]') AND name = N'Jurnale_TVA')
CREATE NONCLUSTERED INDEX [Jurnale_TVA] ON [dbo].[istfact] 
(
	[Data_an] ASC,
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[istfact]') AND name = N'Sub_Tip_Tert')
CREATE NONCLUSTERED INDEX [Sub_Tip_Tert] ON [dbo].[istfact] 
(
	[Data_an] ASC,
	[Subunitate] ASC,
	[Tert] ASC,
	[Tip] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[_pv]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_pv]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[_pv](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Cod_gestiune] [char](9) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Cod_tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Contractul] [char](20) NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Comanda] [char](13) NOT NULL,
	[Gestiune_primitoare] [char](9) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Valoare] [float] NOT NULL,
	[Tva_11] [float] NOT NULL,
	[Tva_22] [float] NOT NULL,
	[Valoare_valuta] [float] NOT NULL,
	[Cota_TVA] [smallint] NOT NULL,
	[Discount_p] [real] NOT NULL,
	[Discount_suma] [float] NOT NULL,
	[Pro_forma] [binary](1) NOT NULL,
	[Tip_miscare] [char](1) NOT NULL,
	[Numar_DVI] [char](13) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Jurnal] [char](3) NOT NULL,
	[Numar_pozitii] [int] NOT NULL,
	[Stare] [smallint] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[_pv]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[_pv] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Numar] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[_pv]') AND name = N'Actualizare')
CREATE UNIQUE NONCLUSTERED INDEX [Actualizare] ON [dbo].[_pv] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Numar] ASC,
	[Jurnal] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[_pv]') AND name = N'Facturare')
CREATE NONCLUSTERED INDEX [Facturare] ON [dbo].[_pv] 
(
	[Subunitate] ASC,
	[Cod_tert] ASC,
	[Factura] ASC,
	[Tip] ASC,
	[Pro_forma] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[_pv]') AND name = N'Numar')
CREATE NONCLUSTERED INDEX [Numar] ON [dbo].[_pv] 
(
	[Numar] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DVI]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DVI]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DVI](
	[Subunitate] [char](9) NOT NULL,
	[Numar_DVI] [char](13) NOT NULL,
	[Data_DVI] [datetime] NOT NULL,
	[Numar_receptie] [char](8) NOT NULL,
	[Data_receptiei] [datetime] NOT NULL,
	[Tert_receptie] [char](13) NOT NULL,
	[Valoare_fara_CIF] [float] NOT NULL,
	[Factura_CIF] [char](20) NOT NULL,
	[Data_CIF] [datetime] NOT NULL,
	[Tert_CIF] [char](13) NOT NULL,
	[Cont_CIF] [char](13) NOT NULL,
	[Procent_CIF] [real] NOT NULL,
	[Valoare_CIF] [float] NOT NULL,
	[Valuta_CIF] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Valoare_CIF_lei] [float] NOT NULL,
	[TVA_CIF] [float] NOT NULL,
	[Total_vama] [float] NOT NULL,
	[Tert_vama] [char](13) NOT NULL,
	[Factura_vama] [char](20) NOT NULL,
	[Cont_vama] [char](13) NOT NULL,
	[Suma_vama] [float] NOT NULL,
	[Cont_suprataxe] [char](13) NOT NULL,
	[Suma_suprataxe] [float] NOT NULL,
	[TVA_22] [float] NOT NULL,
	[TVA_11] [float] NOT NULL,
	[Val_fara_comis] [float] NOT NULL,
	[Tert_comis] [char](13) NOT NULL,
	[Factura_comis] [char](20) NOT NULL,
	[Data_comis] [datetime] NOT NULL,
	[Cont_comis] [char](13) NOT NULL,
	[Valoare_comis] [float] NOT NULL,
	[TVA_comis] [float] NOT NULL,
	[Valoare_intrare] [float] NOT NULL,
	[Valoare_TVA] [float] NOT NULL,
	[Valoare_accize] [float] NOT NULL,
	[Cont_tert_vama] [char](13) NOT NULL,
	[Factura_TVA] [char](20) NOT NULL,
	[Cont_factura_TVA] [char](13) NOT NULL,
	[Cont_vama_suprataxe] [char](13) NOT NULL,
	[Cont_com_vam] [char](13) NOT NULL,
	[Suma_com_vam] [float] NOT NULL,
	[Dif_vama] [float] NOT NULL,
	[Dif_com_vam] [float] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DVI]') AND name = N'Receptie')
CREATE UNIQUE CLUSTERED INDEX [Receptie] ON [dbo].[DVI] 
(
	[Subunitate] ASC,
	[Numar_receptie] ASC,
	[Numar_DVI] ASC,
	[Data_DVI] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DVI]') AND name = N'DVI')
CREATE NONCLUSTERED INDEX [DVI] ON [dbo].[DVI] 
(
	[Subunitate] ASC,
	[Numar_DVI] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[con]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[con]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[con](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Punct_livrare] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Stare] [char](1) NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Termen] [datetime] NOT NULL,
	[Scadenta] [smallint] NOT NULL,
	[Discount] [real] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Mod_plata] [char](1) NOT NULL,
	[Mod_ambalare] [char](1) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Total_contractat] [float] NOT NULL,
	[Total_TVA] [float] NOT NULL,
	[Contract_coresp] [char](20) NOT NULL,
	[Mod_penalizare] [char](13) NOT NULL,
	[Procent_penalizare] [real] NOT NULL,
	[Procent_avans] [real] NOT NULL,
	[Avans] [float] NOT NULL,
	[Nr_rate] [smallint] NOT NULL,
	[Val_reziduala] [float] NOT NULL,
	[Sold_initial] [float] NOT NULL,
	[Cod_dobanda] [char](20) NOT NULL,
	[Dobanda] [real] NOT NULL,
	[Incasat] [float] NOT NULL,
	[Responsabil] [char](20) NOT NULL,
	[Responsabil_tert] [char](20) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Data_rezilierii] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[con]') AND name = N'Principal')
CREATE UNIQUE CLUSTERED INDEX [Principal] ON [dbo].[con] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Contract] ASC,
	[Tert] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[con]') AND name = N'Pe_tert')
CREATE NONCLUSTERED INDEX [Pe_tert] ON [dbo].[con] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Tert] ASC,
	[Data] ASC,
	[Contract] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[con]') AND name = N'Tip_Numar')
CREATE NONCLUSTERED INDEX [Tip_Numar] ON [dbo].[con] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Contract] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [DelExtcon]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DelExtcon]'))
EXEC dbo.sp_executesql @statement = N'--***
Create trigger [dbo].[DelExtcon] on [dbo].[con] for delete
as
Delete from extcon  where exists 
(select * from deleted d where d.subunitate = extcon.subunitate and d.tip = extcon.tip and d.contract = extcon.contract and d.data = extcon.data and d.tert = extcon.tert)'
GO
/****** Object:  Trigger [DVIfac]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DVIfac]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[DVIfac] on [dbo].[DVI] for update,insert,delete with append as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @accimp int, @contfv int
	set @accimp=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIMP''),0)
	set @contfv=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONTFV''),0)
-------------
  /*Inserare pentru factura CIF*/
insert into facturi select subunitate,'''',0x54,factura_CIF,tert_CIF,max(data_CIF),max(data_comis), 0,0,0,max(valuta_CIF), max(curs), 0,0,0, max(cont_CIF),0,0,'''',max(data_CIF) from inserted where tert_CIF<>'''' and factura_CIF not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_CIF and tip=0x54)
group by subunitate,tert_CIF,factura_CIF
  /*Inserare pentru factura vama*/
insert into facturi select subunitate,'''',0x54,factura_vama,tert_vama,max(data_receptiei),max(substring(tert_comis,4,2)+''/''+left(tert_comis,2)+''/''+substring(tert_comis,7,4)), 0,0,0,'''', 0,0,0,0, max(case when @contfv=0 or cont_tert_vama='''' then cont_vama else cont_tert_vama end), 0,0,'''',max(data_receptiei) from inserted where tert_vama<>'''' and factura_vama not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_vama and tip=0x54) and factura_comis in ('''',''D'')
group by subunitate,tert_vama,factura_vama
  /*Inserare pentru factura comision vamal*/
insert into facturi select subunitate,'''',0x54,left(cont_tert_vama,8),tert_vama,max(data_receptiei),max(substring(tert_comis,4,2)+''/''+left(tert_comis,2)+''/''+substring(tert_comis,7,4)), 0,0,0,'''',0,0,0,0, max(cont_com_vam), 0,0,'''',max(data_receptiei) from inserted where @contfv=0 and tert_vama<>'''' and left(cont_tert_vama,8) not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_vama and tip=0x54) and factura_comis in ('''',''D'')
group by subunitate,tert_vama,cont_tert_vama
  /*Inserare pentru factura TVA vama*/
insert into facturi select subunitate,'''',0x54, factura_TVA,tert_vama,max(data_receptiei),max(substring(tert_comis,4,2)+''/''+left(tert_comis,2)+''/''+substring(tert_comis,7,4)), 0,0,0,'''', 0,0,0,0, max(cont_factura_TVA),0,0,'''',max(data_receptiei) from inserted where @contfv=0 and tert_vama<>'''' and factura_TVA not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_vama and tip=0x54) and factura_comis in ('''',''D'')
group by subunitate,tert_vama,factura_TVA

declare @valoare float,@valoarev float,@valoaretva float,@soldf float,@valuta char(3),@gvaluta char(3),@cont char(13), @gcont char(13)
declare @csub char(9),@ctert char(13),@cfactura char(20),@semn int,@suma float,@sumav float,@tva22 float
declare @gsub char(9),@gtert char(13),@gfactura char(20), @gfetch int

declare tmp cursor for
select subunitate,tert_cif as tert,factura_cif as factura,1,valoare_cif_lei as valoare_comis,(case when valuta_cif='''' then 0 else
valoare_cif end),TVA_cif as TVA_comis, valuta_cif, cont_CIF
from inserted where tert_CIF<>''''
union all
select subunitate,tert_vama,factura_vama,1,
suma_vama+suma_suprataxe+dif_vama+(case when @contfv=1 then suma_com_vam+dif_com_vam else 0 end)+(case when @accimp=1 then valoare_accize+tva_11 else 0 end), 0, (case when @contfv=1 and total_vama<>1 then tva_22 else 0 end), '''', (case when @contfv=0 or cont_tert_vama='''' then cont_vama else cont_tert_vama end) 
from inserted where tert_vama<>'''' and factura_comis in ('''',''D'')
union all
select subunitate, tert_vama, left(cont_tert_vama,8), 1, suma_com_vam+dif_com_vam, 0, 0, '''', cont_com_vam 
from inserted where @contfv=0 and tert_vama<>'''' and factura_comis in ('''',''D'')
union all
select subunitate, tert_vama, factura_tva, 1, 0, 0, (case when total_vama<>1 then tva_22 else 0 end), '''', cont_factura_TVA 
from inserted where @contfv=0 and tert_vama<>'''' and factura_comis in ('''',''D'')

union all
select subunitate,tert_cif,factura_cif,-1,valoare_cif_lei,(case when valuta_cif='''' then 0 else valoare_cif end),TVA_cif, valuta_cif, cont_CIF
from deleted where tert_CIF<>'''' 
union all
select subunitate,tert_vama,factura_vama,-1,suma_vama+suma_suprataxe+dif_vama+(case when @contfv=1 then suma_com_vam+dif_com_vam else 0 end)+(case when @accimp=1 then valoare_accize+tva_11 else 0 end), 0, (case when @contfv=1 and total_vama<>1 then tva_22 else 0 end), '''', (case when @contfv=0 or cont_tert_vama='''' then cont_vama else cont_tert_vama end) 
from deleted where tert_vama<>'''' and factura_comis in ('''',''D'')
union all
select subunitate, tert_vama, left(cont_tert_vama,8), -1, suma_com_vam+dif_com_vam, 0, 0, '''', cont_com_vam 
from deleted where @contfv=0 and tert_vama<>'''' and factura_comis in ('''',''D'')
union all
select subunitate,tert_vama,factura_tva, -1, 0, 0, (case when total_vama<>1 then tva_22 else 0 end), '''', cont_factura_TVA 
from deleted where @contfv=0 and tert_vama<>'''' and factura_comis in ('''',''D'') 
order by subunitate,tert,factura

open tmp
fetch next from tmp into @csub,@ctert,@cfactura,@semn,@suma,@sumav,@tva22,@valuta,@cont
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @Valoaretva=0
	set @soldf=0
	set @gvaluta=''''
	set @gcont=''''
	while @gsub=@csub and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
	begin
		set @soldf=@soldf+@suma*@semn+@tva22*@semn
		set @valoare=@valoare+@suma*@semn
		set @valoarev=@valoarev+@sumav*@semn
		set @valoaretva=@valoaretva+@tva22*@semn
		if @semn=1 set @gvaluta=@valuta
		if @semn=1 set @gcont=@cont
		fetch next from tmp into @csub,@ctert,@cfactura,@semn,@suma,@sumav,@tva22,@valuta,@cont
                                set @gfetch=@@fetch_status
	end
	update facturi set valoare=valoare+@valoare, tva_22=tva_22+@valoaretva, sold=sold+@valoare+@valoaretva,
		valoare_valuta=valoare_valuta+@valoarev, sold_valuta=sold_valuta+@valoarev, valuta=(case when @gvaluta='''' then valuta else @gvaluta end), cont_de_tert=(case when @gcont='''' then cont_de_tert else @gcont end)
	        where subunitate=@gsub and tip=0x54 and tert=@gtert and factura=@gfactura
	delete from facturi where subunitate=@gsub and tip=0x54 and tert=@gtert and factura=@gfactura 
		and valoare=0 and tva_22=0 and tva_11=0 and achitat=0 and valoare_valuta=0 and achitat_valuta=0
	set @gsub=@csub
	set @gtert=@ctert
	set @gfactura=@cfactura
end

close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [plinTxinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plinTxinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[plinTxinc] on [dbo].[pozplin] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
		declare @cdtva varchar(13), @cctvaned varchar(13)
		set @cdtva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CDTVA''),''''))
		set @cctvaned=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVANED''),''''))
-------------
/* Chelt. TVA neded. PC */
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, ''PI'', cont, data,
	@cctvaned, @cdtva, 
	0, '''', 0, 0, left(max(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+
	(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii),50), 
	max(utilizator), max(data_operarii), max(ora_operarii), numar_pozitie, loc_de_munca, comanda, max(jurnal)
from inserted 
where @cctvaned<>'''' and plata_incasare=''PC'' and TVA22<>0 and curs_la_valuta_facturii=2 
	and not exists (select 1 from pozincon 
	where subunitate=inserted.subunitate and tip_document=''PI''  and numar_document=inserted.cont and data=inserted.data 
	and cont_debitor=@cctvaned and cont_creditor=@cdtva and loc_de_munca=inserted.loc_de_munca and comanda=inserted.comanda and numar_pozitie=inserted.numar_pozitie) 
group by subunitate, cont, data, loc_de_munca, comanda, numar_pozitie

declare @gsub char(9),@gnr char(13),@gd datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40), @val float, @gpoz float, @gfs int, @gexpl char(50)
declare @sub char(9),@nr char(13),@data datetime,@contd char(13),@contc char(13),@semn int,@suma float, @locm char(9), @com char(40), @poz float, @expl char(50)

declare tmp cursor for
select subunitate, cont as numar, data, @cctvaned as contd, @cdtva as contc, 1,TVA22, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii,50) 
from inserted 
where @cctvaned<>'''' and plata_incasare=''PC'' and TVA22<>0 and curs_la_valuta_facturii=2
union all
select subunitate, cont, data, @cctvaned, @cdtva, -1,TVA22, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii,50) 
from deleted 
where @cctvaned<>'''' and plata_incasare=''PC'' and TVA22<>0 and curs_la_valuta_facturii=2
order by subunitate,numar,data,contd,contc,loc_de_munca,comanda,numar_pozitie

open tmp
fetch next from tmp into @sub,@nr,@data,@contd,@contc,@semn,@suma,@locm,@com,@poz,@expl
set @gsub=@sub
set @gnr=@nr
set @gd=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gpoz=@poz
set @gfs=@@fetch_status
while @gfs=0
begin
	set @val=0
	set @gexpl=@expl
	while @gsub=@sub and @gnr=@nr and @gd=@data and @gctd=@contd and @gctc=@contc 
		and @glm=@locm and @gcom=@com and @gpoz=@poz and @gfs=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub,@nr,@data,@contd,@contc,@semn,@suma,@locm,@com,@poz,@expl
		set @gfs=@@fetch_status
	end
	update pozincon set suma=suma+@val, explicatii=@gexpl
	  where subunitate=@gsub and tip_document=''PI'' and numar_document=@gnr
		and data=@gd and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and numar_pozitie=@gpoz
	delete from pozincon where subunitate=@gsub and tip_document=''PI'' and numar_document=@gnr
		and data=@gd and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and numar_pozitie=@gpoz and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gnr=@nr
	set @gd=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gpoz=@poz
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [plinTinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plinTinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[plinTinc] on [dbo].[pozplin] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @cdtva varchar(13), @cctva varchar(13), @cneexrec varchar(13), @neexav int
	set @cdtva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CDTVA''),''''))	
	set @cctva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVA''),''''))
	set @cneexrec=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CNEEXREC''),''''))
	set @neexav=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''NEEXAV''),0)
-------------
/* TVA ded./col. */
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, ''PI'', cont, data,
	max(case when plata_incasare=''IR'' then @cneexrec when plata_incasare=''IC'' and curs_la_valuta_facturii<>1 or plata_incasare=''IB'' then cont else @cdtva end), 
	max(case when plata_incasare=''PR'' then @cneexrec when plata_incasare in (''IC'',''IB'',''IR'') or plata_incasare=''PC'' and curs_la_valuta_facturii=1 then @cctva else cont end), 
	0, '''', 0, 0, left(max(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+
	(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii),50), 
	max(utilizator), max(data_operarii), max(ora_operarii), numar_pozitie, loc_de_munca, comanda, max(jurnal)
from inserted 
where TVA22<>0 and not (plata_incasare=''IC'' and curs_la_valuta_facturii=2) 
	and not exists (select 1 from pozincon 
	where subunitate=inserted.subunitate and tip_document=''PI''  and numar_document=inserted.cont and data=inserted.data 
	and cont_debitor=(case when plata_incasare=''IR'' then @cneexrec when plata_incasare=''IC'' and curs_la_valuta_facturii<>1 or plata_incasare=''IB'' then inserted.cont else @cdtva end)
	and cont_creditor=(case when plata_incasare=''PR'' then @cneexrec when plata_incasare in (''IC'',''IB'',''IR'') or plata_incasare=''PC'' and curs_la_valuta_facturii=1 then @cctva else inserted.cont end) 
	and loc_de_munca=inserted.loc_de_munca and comanda=inserted.comanda and numar_pozitie=inserted.numar_pozitie) 
group by subunitate, data, cont, cont_corespondent, loc_de_munca, comanda, numar_pozitie
/* TVA avans */
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, ''PI'', cont, data, max(case when plata_incasare=''IB'' then @cneexrec else cont_corespondent end),
	max(case when plata_incasare=''PF'' then @cneexrec else cont_corespondent end), 0, '''', 0, 0, 
	left(max(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+
	(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii),50), 
	max(utilizator), max(data_operarii), max(ora_operarii), numar_pozitie, loc_de_munca, comanda, max(jurnal)
from inserted 
where @neexav=0 and plata_incasare in (''IB'',''PF'') and TVA22<>0 and not exists (select 1 from pozincon where subunitate= inserted.subunitate and tip_document=''PI'' and numar_document=inserted.cont and data=inserted.data and cont_debitor=(case when inserted.plata_incasare=''IB'' then @cneexrec else inserted.cont_corespondent end) and cont_creditor= (case when inserted.plata_incasare=''PF'' then @cneexrec else inserted.cont_corespondent end) and loc_de_munca=inserted.loc_de_munca and comanda=inserted.comanda and numar_pozitie= inserted.numar_pozitie) group by subunitate, data, cont, cont_corespondent, loc_de_munca, comanda, numar_pozitie

declare @gsub char(9),@gnr char(13),@gd datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40), @val float, @gpoz float, @gfs int, @gexpl char(50)
declare @sub char(9),@nr char(13),@data datetime,@contd char(13),@contc char(13),@semn int,@suma float, @locm char(9), @com char(40), @poz float, @expl char(50)

declare tmp cursor for
select subunitate, cont as numar, data, (case when plata_incasare=''IR'' then @cneexrec when plata_incasare=''IC'' and curs_la_valuta_facturii<>1 or plata_incasare=''IB'' then cont else @cdtva end) as contd, (case when plata_incasare=''PR'' then @cneexrec when plata_incasare in (''IC'',''IB'',''IR'') or plata_incasare=''PC'' and curs_la_valuta_facturii=1 then @cctva else cont end) as contc, 1,TVA22, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii,50) 
from inserted where TVA22<>0 and not (plata_incasare=''IC'' and curs_la_valuta_facturii=2)
union all
select subunitate, cont, data, (case when plata_incasare=''IB'' then @cneexrec else cont_corespondent end), (case when plata_incasare=''PF'' then @cneexrec else cont_corespondent end), 1,TVA22, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii,50) 
from inserted where @neexav=0 and plata_incasare in (''IB'',''PF'') and TVA22<>0 
union all
select subunitate, cont, data, (case when plata_incasare=''IR'' then @cneexrec when plata_incasare=''IC'' and curs_la_valuta_facturii<>1 or plata_incasare=''IB'' then cont else @cdtva end), (case when plata_incasare=''PR'' then @cneexrec when plata_incasare in (''IC'',''IB'',''IR'') or plata_incasare=''PC'' and curs_la_valuta_facturii=1 then @cctva else cont end), -1,TVA22, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii,50) 
from deleted where TVA22<>0 and not (plata_incasare=''IC'' and curs_la_valuta_facturii=2)
union all
select subunitate, cont, data, (case when plata_incasare=''IB'' then @cneexrec else cont_corespondent end), (case when plata_incasare=''PF'' then @cneexrec else cont_corespondent end), -1,TVA22, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''fact. ''+rtrim(factura)+'' '' end)+explicatii,50) 
from deleted where @neexav=0 and plata_incasare in (''IB'',''PF'') and TVA22<>0 
order by subunitate,numar,data,contd,contc,loc_de_munca,comanda,numar_pozitie

open tmp
fetch next from tmp into @sub,@nr,@data,@contd,@contc,@semn,@suma,@locm,@com,@poz,@expl
set @gsub=@sub
set @gnr=@nr
set @gd=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gpoz=@poz
set @gfs=@@fetch_status
while @gfs=0
begin
	set @val=0
	set @gexpl=@expl
	while @gsub=@sub and @gnr=@nr and @gd=@data and @gctd=@contd and @gctc=@contc 
		and @glm=@locm and @gcom=@com and @gpoz=@poz and @gfs=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub,@nr,@data,@contd,@contc,@semn,@suma,@locm,@com,@poz,@expl
		set @gfs=@@fetch_status
	end
	update pozincon set suma=suma+@val, explicatii=@gexpl
	  where subunitate=@gsub and tip_document=''PI'' and numar_document=@gnr
		and data=@gd and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and numar_pozitie=@gpoz
	delete from pozincon where subunitate=@gsub and tip_document=''PI'' and numar_document=@gnr
		and data=@gd and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and numar_pozitie=@gpoz and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gnr=@nr
	set @gd=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gpoz=@poz
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [plininc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[plininc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[plininc] on [dbo].[pozplin] for update,insert,delete with append as
begin
-------------	din tabela par (parametri trimis de Magic):
		declare @bugetari int, @contcob char(13), @invdifinr int
		set @bugetari=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''BUGETARI''),0)
		set @contcob=isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CONTCOB''),'''')
		set @invdifinr=isnull((select top 1 Val_logica from par where tip_parametru=''GE'' and parametru=''INVDIFINR''),0)
-------------
/* Inreg. de baza */
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, ''PI'', a.cont, a.data,
	max(case when left(a.plata_incasare,1)=''I'' then a.cont else a.cont_corespondent end), 
	max(case when left(a.plata_incasare,1)=''I'' then a.cont_corespondent else a.cont end),
	0, a.valuta, max(a.curs), 0, left(max(a.plata_incasare+'' ''+rtrim(a.numar)+'' ''+
	(case when a.valuta='''' then '''' else rtrim(a.valuta)+'' '' end)+
	(case when a.factura='''' then '''' else ''f. ''+rtrim(a.factura)+'' '' end)+a.explicatii),50), 
	max(utilizator), max(data_operarii), max(ora_operarii), numar_pozitie, loc_de_munca, comanda, max(a.jurnal)
from inserted a
where not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=''PI''
and numar_document=a.cont and data=a.data and cont_debitor=(case when left(a.plata_incasare,1)=''I'' then a.cont else a.cont_corespondent end) and cont_creditor=(case when left(a.plata_incasare,1)=''I'' then a.cont_corespondent else a.cont end) 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and numar_pozitie=a.numar_pozitie and valuta=a.valuta) 
group by a.subunitate, a.data, a.cont, a.cont_corespondent, a.loc_de_munca, a.comanda, a.numar_pozitie, a.valuta
/* Dif. curs */
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, ''PI'', cont, data,
	max(case when @bugetari=1 and cont_dif<>'''' then @contcob when left(plata_incasare,1)=''I'' then (case when suma_dif>0 then cont 
	else cont_dif end) else (case when suma_dif>0 then cont_dif when @invdifinr=1 then cont else cont_corespondent end) end), 
	max(case when @bugetari=1 and cont_dif<>'''' then cont_dif when left(plata_incasare,1)=''I'' then case when suma_dif>0 
	then cont_dif when @invdifinr=1 then cont else cont_corespondent end else case when suma_dif>0 then cont else cont_dif end end),
	0, '''', 0, 0, left(max(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+
	(case when factura='''' then '''' else ''f. ''+rtrim(factura)+'' '' end)+explicatii),50), 
	max(utilizator), max(data_operarii), max(ora_operarii), numar_pozitie, loc_de_munca, comanda, max(jurnal)
from inserted 
where @bugetari=0 and cont_dif<>'''' and suma_dif<>0 and not exists (select 1 from pozincon where subunitate=inserted.subunitate and tip_document=''PI'' and numar_document=inserted.cont and data=inserted.data and cont_debitor=(case when @bugetari=1 and inserted.cont_dif<>'''' then @contcob when left(inserted.plata_incasare,1)=''I'' then (case when inserted.suma_dif>0 then inserted.cont else inserted.cont_dif end) else (case when inserted.suma_dif>0 then inserted.cont_dif when @invdifinr=1 then inserted.cont else inserted.cont_corespondent end) end) and cont_creditor=(case when @bugetari=1 and inserted.cont_dif<>'''' then inserted.cont_dif when left(inserted.plata_incasare,1)=''I'' then (case when inserted.suma_dif>0 then inserted.cont_dif when @invdifinr=1 then inserted.cont else inserted.cont_corespondent end) else (case when inserted.suma_dif>0 then inserted.cont else inserted.cont_dif end) end) and loc_de_munca=inserted.loc_de_munca and comanda=inserted.comanda and numar_pozitie=inserted.numar_pozitie) group by subunitate, data, cont, cont_corespondent, loc_de_munca, comanda, numar_pozitie

declare @gsub char(9),@gnr char(13),@gd datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40), @val float, @valv float, @gvaluta char(3), @gcurs float, @gpoz float, @gexpl char(50), @gfs int
declare @sub char(9),@nr char(13),@data datetime,@contd char(13),@contc char(13),@semn int,@suma float,@sumav float,
@valuta char(3),@curs float,@locm char(9),@com char(40),@poz float, @expl char(50)

declare tmp cursor for
select subunitate, cont as numar, data,(case when left(plata_incasare,1)=''I'' then cont else cont_corespondent end) as contd, 
(case when left(plata_incasare,1)=''I'' then cont_corespondent else cont end) as contc, 1, suma-(case when plata_incasare in (''PR'',''IR'') then 0 else TVA22 end)-(case when @bugetari=1 and cont_dif<>'''' then 0 when suma_dif<0 and @invdifinr=0 then 0 else suma_dif end), suma_valuta, valuta, curs, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''f. ''+rtrim(factura)+'' '' end)+explicatii,50)
from inserted 
union all
select subunitate, cont, data, (case when @bugetari=1 and cont_dif<>'''' then @contcob when left(plata_incasare,1)=''I'' then case when suma_dif>0 then cont else cont_dif end else case when suma_dif>0 then cont_dif when @invdifinr=1 then cont else cont_corespondent end end), (case when @bugetari=1 and cont_dif<>'''' then cont_dif when left(plata_incasare,1)=''I'' then case when suma_dif>0 then cont_dif when @invdifinr=1 then cont else cont_corespondent end else case when suma_dif>0 then cont else cont_dif end end), 1, (case when @bugetari=1 and cont_dif<>'''' then 1 when suma_dif<0 then -1 else 1 end)*suma_dif,0,'''',0,loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''f. ''+rtrim(factura)+'' '' end)+explicatii,50)
from inserted where @bugetari=0 and cont_dif<>'''' and suma_dif<>0 
union all 
select subunitate, cont, data, (case when left(plata_incasare,1)=''I'' then cont else cont_corespondent end), 
(case when left(plata_incasare,1)=''I'' then cont_corespondent else cont end), -1, suma-(case when plata_incasare in (''PR'',''IR'') then 0 else TVA22 end)-(case when @bugetari=1 and cont_dif<>'''' then 0 when suma_dif<0 and @invdifinr=0 then 0 else suma_dif end), suma_valuta, valuta, curs, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''f. ''+rtrim(factura)+'' '' end)+explicatii,50)
from deleted 
union all
select subunitate, cont, data, (case when @bugetari=1 and cont_dif<>'''' then @contcob when left(plata_incasare,1)=''I'' then case when suma_dif>0 then cont else cont_dif end else case when suma_dif>0 then cont_dif when @invdifinr=1 then cont else cont_corespondent end end), (case when @bugetari=1 and cont_dif<>'''' then cont_dif when left(plata_incasare,1)=''I'' then case when suma_dif>0 then cont_dif when @invdifinr=1 then cont else cont_corespondent end else case when suma_dif>0 then cont else cont_dif end end), -1, (case when @bugetari=1 and cont_dif<>'''' then 1 when suma_dif<0 then -1 else 1 end)*suma_dif, 0, '''', 0, loc_de_munca, comanda, numar_pozitie, left(plata_incasare+'' ''+rtrim(numar)+'' ''+(case when valuta='''' then '''' else rtrim(valuta)+'' '' end)+(case when factura='''' then '''' else ''f. ''+rtrim(factura)+'' '' end)+explicatii,50)
from deleted where @bugetari=0 and cont_dif<>'''' and suma_dif<>0
order by subunitate,numar,data,contd,contc,loc_de_munca,comanda,numar_pozitie,valuta

open tmp
fetch next from tmp into @sub,@nr,@data,@contd,@contc,@semn,@suma,@sumav,@valuta,@curs,@locm,@com,@poz,@expl
set @gsub=@sub
set @gnr=@nr
set @gd=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gpoz=@poz
set @gvaluta=@valuta
set @gfs=@@fetch_status
while @gfs=0
begin
	set @val=0
	set @valv=0
	set @gcurs=@curs
	set @gexpl=@expl
	while @gsub=@sub and @gnr=@nr and @gd=@data and @gctd=@contd and @gctc=@contc 
		and @glm=@locm and @gcom=@com and @gpoz=@poz and @gvaluta=@valuta and @gfs=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		--if @semn=1 set @gvaluta=@valuta
		if @semn=1 set @gcurs=@curs
		if @semn=1 set @gexpl=@expl
		fetch next from tmp into @sub,@nr,@data,@contd,@contc,@semn,
			@suma,@sumav,@valuta,@curs,@locm,@com,@poz, @expl
		set @gfs=@@fetch_status
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+@valv, curs=@gcurs, 
	  explicatii=@gexpl where subunitate=@gsub and tip_document=''PI'' and numar_document=@gnr
		and data=@gd and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and numar_pozitie=@gpoz and valuta=@gvaluta
	delete from pozincon where subunitate=@gsub and tip_document=''PI'' and numar_document=@gnr
		and data=@gd and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and numar_pozitie=@gpoz and valuta=@gvaluta
		and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gnr=@nr
	set @gd=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gpoz=@poz
	set @gvaluta=@valuta
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Table [dbo].[pozadoc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozadoc]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[pozadoc](
	[Subunitate] [char](9) NOT NULL,
	[Numar_document] [char](8) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Factura_stinga] [char](20) NOT NULL,
	[Factura_dreapta] [char](20) NOT NULL,
	[Cont_deb] [char](13) NOT NULL,
	[Cont_cred] [char](13) NOT NULL,
	[Suma] [float] NOT NULL,
	[TVA11] [float] NOT NULL,
	[TVA22] [float] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Tert_beneficiar] [char](13) NOT NULL,
	[Explicatii] [char](50) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Suma_valuta] [float] NOT NULL,
	[Cont_dif] [char](13) NOT NULL,
	[suma_dif] [float] NOT NULL,
	[Loc_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Data_fact] [datetime] NOT NULL,
	[Data_scad] [datetime] NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Achit_fact] [float] NOT NULL,
	[Dif_TVA] [float] NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozadoc]') AND name = N'Actualizare')
CREATE UNIQUE CLUSTERED INDEX [Actualizare] ON [dbo].[pozadoc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Numar_document] ASC,
	[Data] ASC,
	[Numar_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozadoc]') AND name = N'Dreapta')
CREATE NONCLUSTERED INDEX [Dreapta] ON [dbo].[pozadoc] 
(
	[Subunitate] ASC,
	[Tert] ASC,
	[Factura_dreapta] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozadoc]') AND name = N'Stanga')
CREATE NONCLUSTERED INDEX [Stanga] ON [dbo].[pozadoc] 
(
	[Subunitate] ASC,
	[Tert] ASC,
	[Factura_stinga] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[pozdoc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozdoc]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[pozdoc](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Numar] [char](8) NOT NULL,
	[Cod] [char](30) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Gestiune] [char](9) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret_valuta] [float] NOT NULL,
	[Pret_de_stoc] [float] NOT NULL,
	[Adaos] [real] NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Pret_cu_amanuntul] [float] NOT NULL,
	[TVA_deductibil] [float] NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL,
	[Cod_intrare] [char](30) NOT NULL,
	[Cont_de_stoc] [char](13) NOT NULL,
	[Cont_corespondent] [char](13) NOT NULL,
	[TVA_neexigibil] [real] NOT NULL,
	[Pret_amanunt_predator] [float] NOT NULL,
	[Tip_miscare] [char](1) NOT NULL,
	[Locatie] [char](30) NOT NULL,
	[Data_expirarii] [datetime] NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Loc_de_munca] [char](9) NOT NULL,
	[Comanda] [char](40) NOT NULL,
	[Barcod] [char](30) NOT NULL,
	[Cont_intermediar] [char](13) NOT NULL,
	[Cont_venituri] [char](13) NOT NULL,
	[Discount] [real] NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Factura] [char](20) NOT NULL,
	[Gestiune_primitoare] [char](13) NOT NULL,
	[Numar_DVI] [char](25) NOT NULL,
	[Stare] [smallint] NOT NULL,
	[Grupa] [char](13) NOT NULL,
	[Cont_factura] [char](13) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Curs] [float] NOT NULL,
	[Data_facturii] [datetime] NOT NULL,
	[Data_scadentei] [datetime] NOT NULL,
	[Procent_vama] [real] NOT NULL,
	[Suprataxe_vama] [float] NOT NULL,
	[Accize_cumparare] [float] NOT NULL,
	[Accize_datorate] [float] NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Jurnal] [char](3) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozdoc]') AND name = N'Pentru_culegere')
CREATE UNIQUE CLUSTERED INDEX [Pentru_culegere] ON [dbo].[pozdoc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Numar] ASC,
	[Data] ASC,
	[Numar_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozdoc]') AND name = N'Balanta')
CREATE NONCLUSTERED INDEX [Balanta] ON [dbo].[pozdoc] 
(
	[Subunitate] ASC,
	[Gestiune] ASC,
	[Cod] ASC,
	[Cod_intrare] ASC,
	[Data] ASC,
	[Tip_miscare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozdoc]') AND name = N'Principal')
CREATE UNIQUE NONCLUSTERED INDEX [Principal] ON [dbo].[pozdoc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Numar] ASC,
	[Gestiune] ASC,
	[Cod] ASC,
	[Cod_intrare] ASC,
	[Numar_pozitie] ASC,
	[Pret_vanzare] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozdoc]') AND name = N'Terti')
CREATE NONCLUSTERED INDEX [Terti] ON [dbo].[pozdoc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Tert] ASC,
	[Factura] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [realizpozprod]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[realizpozprod]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[realizpozprod] on [dbo].[pozdoc] for insert, update, delete not for replication as
begin
declare @cSb char(9), @cComProd char(20), @cCod char(20), @nCantPredare float, 
	@cComLivr char(20), @dLivr datetime, @cBenef char(13), @nCantComandata float, @nCantRealizata float, 
	@nCantDescarc float
set @cSb=isnull((select max(val_alfanumerica) from par where tip_parametru=''GE'' and parametru=''SUBPRO''), '''')
-- cantitate PP => realizata pozprod
declare tmpcmdpred cursor for
select isnull(i.comanda, d.comanda) as comanda, isnull(i.cod, d.cod) as cod, 
sum(isnull(i.cantitate, 0))-sum(isnull(d.cantitate, 0)) as diferenta 
from inserted i full outer join deleted d 
	on i.subunitate=d.subunitate and i.tip=d.tip and i.numar=d.numar and i.data=d.data and i.numar_pozitie=d.numar_pozitie 
		and i.cod=d.cod and i.comanda=d.comanda
where isnull(i.subunitate, d.subunitate)=@cSb and isnull(i.tip, d.tip)=''PP'' and isnull(i.comanda, d.comanda)<>''''
group by isnull(i.comanda, d.comanda), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cantitate, 0))-sum(isnull(d.cantitate, 0))) >= 0.001
open tmpcmdpred
fetch next from tmpcmdpred into @cComProd, @cCod, @nCantPredare
while @@fetch_status = 0
begin
	declare tmppozprod cursor for
	select comanda_livrare, data_comenzii, beneficiar, cantitate_comandata, cantitate_realizata
	from pozprod 
	where comanda=@cComProd and cod=@cCod
	order by datediff(day, getdate(), data_comenzii) * sign(@nCantPredare), 
		(case when sign(@nCantPredare)>0 then comanda_livrare else '''' end) ASC,
		(case when sign(@nCantPredare)<0 then comanda_livrare else '''' end) DESC
	open tmppozprod
	fetch next from tmppozprod into @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantRealizata
	while @@fetch_status = 0 and abs(@nCantPredare) >= 0.001
	begin
		if @nCantPredare > 0 
			set @nCantDescarc = (case when @nCantComandata - @nCantRealizata < @nCantPredare then @nCantComandata - @nCantRealizata else @nCantPredare end)
		else 
			set @nCantDescarc = (case when @nCantRealizata < abs(@nCantPredare) then (-1) * @nCantRealizata else @nCantPredare end)
		
		set @nCantPredare = @nCantPredare - @nCantDescarc
		update pozprod set cantitate_realizata = cantitate_realizata + @nCantDescarc
		where comanda=@cComProd and cod=@cCod and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozprod into @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantRealizata
	end
	close tmppozprod
	deallocate tmppozprod
	fetch next from tmpcmdpred into @cComProd, @cCod, @nCantPredare
end
close tmpcmdpred
deallocate tmpcmdpred

end
'
GO
/****** Object:  Trigger [docXzinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docXzinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docXzinc] on [dbo].[pozdoc] for update, insert, delete as
begin 
-------------	din tabela par (parametri trimis de Magic):
declare @ctrezrep char(13), @inversAmReev int 
set @ctrezrep=isnull((select top 1 val_alfanumerica from par where tip_parametru=''MF'' and parametru=''CTREZREP''),'''')		
set @inversAmReev=isnull((select top 1 val_logica from par where tip_parametru=''MF'' and parametru=''INVCTREEV''),0)		
-------------

--Amortizare af.grd. neutilizare mfix
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar, a.data, 
(case when a.tip in (''RM'', ''AI'') then left(a.barcod, 13) else '''' end), 
(case when a.tip in (''RM'', ''AI'') then '''' else left(a.barcod, 13) end), 
0, '''', 0, 0, ''Amortizare af.grd. neutilizare'', 
max(a.utilizator), max(a.data_operarii), max(a.ora_operarii), 0, a.loc_de_munca, a.comanda, max(a.jurnal)
from inserted a inner join nomencl n on a.cod=n.cod 
where a.tip in (''AP'', ''AI'', ''AE'', ''RM'') and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') 
and n.tip=''F'' and a.accize_cumparare<>0 and left(a.barcod, 1)=''8'' and a.jurnal=''MFX''
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data 
 and cont_debitor=(case when a.tip in (''RM'', ''AI'') then left(a.barcod, 13) else '''' end) 
 and cont_creditor=(case when a.tip in (''RM'', ''AI'') then '''' else left(a.barcod, 13) end) 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, left(a.barcod, 13), a.loc_de_munca, a.comanda

--val. amortizata/rezultat reportat mfix
insert pozincon
select a.subunitate, a.tip, a.numar, a.data, 
(case when a.tip in (''AE'',''AP'') then a.locatie when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cont_corespondent else a.gestiune_primitoare end), 
(case when a.tip in (''AE'',''AP'') then a.contract when a.tip=''RM'' then a.cont_intermediar when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.gestiune_primitoare else a.cont_factura end), 
0, '''', 0, 0, (case when a.tip in (''AE'',''AP'') then ''Rezerve reev.sau rezultat rep.'' else ''Val. amortizata'' end), 
max(a.utilizator), max(a.data_operarii), max(a.ora_operarii), 0, a.loc_de_munca, a.comanda, max(a.jurnal)
from inserted a inner join nomencl n on a.cod=n.cod 
where n.tip=''F'' and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') 
and (a.tip in (''AE'',''AP'') and a.contract<>'''' and a.suprataxe_vama<>0 or a.tip in (''RM'', ''AI'') and a.accize_datorate<>0)
and a.jurnal=''MFX''
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data 
 and cont_debitor=(case when a.tip in (''AE'',''AP'') then a.locatie when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cont_corespondent else a.gestiune_primitoare end) 
 and cont_creditor=(case when a.tip in (''AE'',''AP'') then a.contract when a.tip=''RM'' then a.cont_intermediar when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.gestiune_primitoare else a.cont_factura end) 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, 
(case when a.tip in (''AE'',''AP'') then a.locatie when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cont_corespondent else a.gestiune_primitoare end), 
(case when a.tip in (''AE'',''AP'') then a.contract when a.tip=''RM'' then a.cont_intermediar when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.gestiune_primitoare else a.cont_factura end), 
a.loc_de_munca, a.comanda

--rezerve ct.106
insert pozincon
select a.subunitate, a.tip, a.numar, a.data, 
a.cont_corespondent, @ctrezrep, 
0, '''', 0, 0, ''Rezerve'', 
max(a.utilizator), max(a.data_operarii), max(a.ora_operarii), 0, a.loc_de_munca, a.comanda, max(a.jurnal)
from inserted a inner join nomencl n on a.cod=n.cod 
where n.tip=''F'' and a.tip in (''AI'') and a.pret_amanunt_predator<>0 
and a.jurnal=''MFX''
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data 
 and cont_debitor=a.cont_corespondent 
 and cont_creditor=@ctrezrep 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, a.cont_corespondent, a.loc_de_munca, a.comanda

--rezerve ct.105 sau ajustari
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar, a.data, a.tert, a.cont_venituri, 
0, '''', 0, 0, ''Rezerve din reev. sau ajustari'', 
max(a.utilizator), max(a.data_operarii), max(a.ora_operarii), 0, a.loc_de_munca, a.comanda, max(a.jurnal)
from inserted a inner join nomencl n on a.cod=n.cod 
where a.tip=''AI'' and n.tip=''F'' and a.suprataxe_vama<>0 and a.jurnal=''MFX''
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data and cont_debitor=a.tert and cont_creditor=a.cont_venituri 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, a.tert, a.cont_venituri, a.loc_de_munca, a.comanda


declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
@gcom char(40), @val float, @gfetch int, @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, @suma float, @locm char(9), @com char(40)

declare tmp cursor for
select a.subunitate, a.tip as tipdoc, a.numar, a.data, 
(case when a.tip in (''RM'', ''AI'') then left(a.barcod, 13) else '''' end) as contd, 
(case when a.tip in (''RM'', ''AI'') then '''' else left(a.barcod, 13) end) as contc, 
1, round (/*a.cantitate**/a.accize_cumparare, 2), a.loc_de_munca as loc_munca, a.comanda 
from inserted a inner join nomencl n on a.cod=n.cod
where a.tip in (''AP'', ''AI'', ''AE'', ''RM'') and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') 
and n.tip=''F'' and a.accize_cumparare<>0 and left(a.barcod, 1)=''8'' and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, 
(case when a.tip in (''AE'',''AP'') then a.locatie when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cont_corespondent else a.gestiune_primitoare end), 
(case when a.tip in (''AE'',''AP'') then a.contract when a.tip=''RM'' then a.cont_intermediar when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.gestiune_primitoare else a.cont_factura end), 
(case when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then -1 else 1 end), 
round (/*a.cantitate**/(case when a.tip in (''AE'',''AP'') then a.suprataxe_vama else a.accize_datorate end), 2), 
a.loc_de_munca as loc_munca, a.comanda 
from inserted a inner join nomencl n on a.cod=n.cod
where n.tip=''F'' and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') 
and (a.tip in (''AE'',''AP'') and a.contract<>'''' and a.suprataxe_vama<>0 or a.tip in (''RM'', ''AI'') and a.accize_datorate<>0)
and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, 
a.cont_corespondent, @ctrezrep, 
1, round (a.cantitate*a.pret_amanunt_predator, 2), 
a.loc_de_munca, a.comanda 
from inserted a inner join nomencl n on a.cod=n.cod
where n.tip=''F'' and a.tip in (''AI'') and a.pret_amanunt_predator<>0
and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, a.tert, a.cont_venituri, 
1, round (/*a.cantitate**/a.suprataxe_vama, 2), a.loc_de_munca as loc_munca, a.comanda 
from inserted a inner join nomencl n on a.cod=n.cod
where a.tip=''AI'' and n.tip=''F'' and a.suprataxe_vama<>0 and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, 
(case when a.tip in (''RM'', ''AI'') then left(a.barcod, 13) else '''' end), 
(case when a.tip in (''RM'', ''AI'') then '''' else left(a.barcod, 13) end), 
-1, round (/*a.cantitate**/a.accize_cumparare, 2), a.loc_de_munca, a.comanda 
from deleted a inner join nomencl n on a.cod=n.cod
where a.tip in (''AP'', ''AI'', ''AE'', ''RM'') and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') 
and n.tip=''F'' and a.accize_cumparare<>0 and left(a.barcod, 1)=''8'' and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, 
(case when a.tip in (''AE'',''AP'') then a.locatie when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cont_corespondent else a.gestiune_primitoare end), 
(case when a.tip in (''AE'',''AP'') then a.contract when a.tip=''RM'' then a.cont_intermediar when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.gestiune_primitoare else a.cont_factura end), 
(case when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then 1 else -1 end), 
round (/*a.cantitate**/(case when a.tip in (''AE'',''AP'') then a.suprataxe_vama else a.accize_datorate end), 2), 
a.loc_de_munca as loc_munca, a.comanda 
from deleted a inner join nomencl n on a.cod=n.cod
where n.tip=''F'' and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') 
and (a.tip in (''AE'',''AP'') and a.contract<>'''' and a.suprataxe_vama<>0 or a.tip in (''RM'', ''AI'') and a.accize_datorate<>0)
and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, 
a.cont_corespondent, @ctrezrep, 
-1, round (a.cantitate*a.pret_amanunt_predator, 2), 
a.loc_de_munca, a.comanda 
from deleted a inner join nomencl n on a.cod=n.cod
where n.tip=''F'' and a.tip in (''AI'') and a.pret_amanunt_predator<>0
and a.jurnal=''MFX''
union all
select a.subunitate, a.tip, a.numar, a.data, a.tert, a.cont_venituri, 
-1, round (/*a.cantitate**/a.suprataxe_vama, 2), a.loc_de_munca as loc_munca, a.comanda 
from deleted a inner join nomencl n on a.cod=n.cod
where a.tip=''AI'' and n.tip=''F'' and a.suprataxe_vama<>0 and a.jurnal=''MFX''
order by subunitate, tipdoc, numar, data, contd, contc, loc_munca, comanda

open tmp
fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn, @suma, @locm, @com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn, 
			@suma, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val 
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata 
	  and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta='''' 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docXyinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docXyinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docXyinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-------------	din tabela par (parametri trimis de Magic):
		declare @timbrult2 int, @a_categpro int, @caccize char(13), @cchaccize char(13)
		set @timbrult2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULT2''),0)
		set @a_categpro=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIZE''),0)
			if (@a_categpro=1)	set @a_categpro=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CATEGPRO''),0)
		set @caccize=isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CACCIZE''),'''')
		set @cchaccize=isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCHACCIZE''),'''')
-------------
-- timbru literar 2
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, tip, numar, data, cont_de_stoc, (case when tip=''TE'' then cont_intermediar else grupa end), 0, '''', 0, 0, 
 max((''Timbru literar '')+tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)), 
 max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, gestiuni b where @timbrult2=1 and a.tip in (''RM'',''TE'') and a.accize_cumparare<>0 and not exists 
 (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data and cont_debitor=a.cont_de_stoc and cont_creditor=(case when tip=''TE'' then cont_intermediar else grupa end) 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
 and a.gestiune = b.cod_gestiune and b.tip_gestiune in (''C'',''A'')
group by a.subunitate, a.tip, a.numar, a.data, a.cont_de_stoc, (case when tip=''TE'' then cont_intermediar else grupa end) , a.loc_de_munca, a.comanda
-- accize TE
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, tip, numar, data, @cchaccize, @caccize, 0, '''', 0, 0, 
 max((''Accize '')+tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)), 
 max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, gestiuni b where @a_categpro=1 and a.tip=''TE'' and a.accize_datorate<>0 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=@cchaccize and cont_creditor=@caccize 
	and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
and a.gestiune_primitoare=b.cod_gestiune and b.tip_gestiune in (''A'',''V'')
group by a.subunitate, a.tip, a.numar, a.data, a.loc_de_munca, a.comanda
-- timbru literar TE2
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, tip, numar, data, cont_corespondent, cont_intermediar, 0, '''', 0, 0, 
 max((''Timbru literar '')+tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)), 
 max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, gestiuni b where @timbrult2=1 and a.tip in (''TE'') and a.accize_cumparare<>0 and not exists 
 (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data and cont_debitor=a.cont_corespondent and cont_creditor=cont_intermediar 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
 and a.gestiune = b.cod_gestiune and b.tip_gestiune in (''C'',''A'')
group by a.subunitate, a.tip, a.numar, a.data, a.cont_corespondent, a.cont_intermediar, a.loc_de_munca, a.comanda

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
@gcom char(40), @val float, @gfetch int, @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, @suma float, @locm char(9), @com char(40)

declare tmp cursor for
select subunitate, tip, numar, data, cont_de_stoc as contd, (case when tip=''TE'' then cont_intermediar else grupa end) as contc, 
1, (case when tip=''TE'' then -1 else 1 end)*cantitate*accize_cumparare, loc_de_munca, comanda 
from inserted where @timbrult2=1 and tip in (''RM'',''TE'') and accize_cumparare<>0 
union all
select a.subunitate, a.tip, a.numar, a.data, @cchaccize, @caccize, 
1, a.accize_datorate, a.loc_de_munca, a.comanda 
from inserted a, gestiuni b
where @a_categpro=1 and a.tip=''TE'' and a.accize_datorate<>0 and a.subunitate=b.subunitate and a.gestiune_primitoare=b.cod_gestiune and b.tip_gestiune in (''A'', ''V'')
union all
select subunitate, tip, numar, data, cont_corespondent, cont_intermediar, 
1, cantitate*accize_cumparare, loc_de_munca, comanda 
from inserted where @timbrult2=1 and tip in (''TE'') and accize_cumparare<>0 
union all
select subunitate, tip, numar, data, cont_de_stoc, (case when tip=''TE'' then cont_intermediar else grupa end), 
-1, (case when tip=''TE'' then -1 else 1 end)*cantitate*accize_cumparare, loc_de_munca, comanda 
from deleted where @timbrult2=1 and tip in (''RM'',''TE'') and accize_cumparare<>0 
union all
select a.subunitate, a.tip, a.numar, a.data, @cchaccize, @caccize, 
-1, a.accize_datorate, a.loc_de_munca, a.comanda 
from deleted a, gestiuni b
where @a_categpro=1 and a.tip=''TE'' and a.accize_datorate<>0 and a.subunitate=b.subunitate and a.gestiune_primitoare=b.cod_gestiune and b.tip_gestiune in (''A'', ''V'')
union all
select subunitate, tip, numar, data, cont_corespondent, cont_intermediar, 
-1, cantitate*accize_cumparare, loc_de_munca, comanda 
from deleted where @timbrult2=1 and tip in (''TE'') and accize_cumparare<>0 
order by subunitate, tip, numar, data, contd, contc, loc_de_munca, comanda

open tmp
fetch next from tmp into @sub,@tip,@numar,@data, @contd,@contc,@semn,@suma, @locm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val 
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata 
	  and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta='''' 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docXstoc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docXstoc]'))
EXEC dbo.sp_executesql @statement = N'--*** folosinta si custodie pe terti, mai putin cazul folosinta in pret mediu 
create trigger [dbo].[docXstoc] on [dbo].[pozdoc] for insert,update,delete with append as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @timbruVaccize int, @stcust35 int, @mediup_l int, @medpexfol int, @l_stocuri_codgestiune int, @l_stocuri_locatie int, @stcust8 int
	set @timbruVaccize=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULIT''),0)
		if (@timbruVaccize=0) set @timbruVaccize=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIZE''),0)
	set @stcust35=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STCUST35''),0)
	set @mediup_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MEDIUP''),0)
	set @medpexfol=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MEDPEXFOL''),0)
	-- LuciM: am unificat, deoarece expresia originala era (@mediup_l=0 or @medpexfol=1)
	if @medpexfol=1 -- Ghita: daca execptie folosinta e ca si cum nu s-ar lucra cu pret mediu
		set @mediup_l=0

	set @l_stocuri_codgestiune=isnull((select top 1 syscolumns.length from syscolumns,sysobjects where sysobjects.name=''stocuri'' and 
											sysobjects.id=syscolumns.id and syscolumns.name=''cod_gestiune''),0)
	set @l_stocuri_locatie=isnull((select top 1 syscolumns.length from syscolumns,sysobjects where sysobjects.name=''stocuri'' and 
											sysobjects.id=syscolumns.id and syscolumns.name=''locatie''),0)
	set @stcust8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STCUST8''),0)
-------------
insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1)
	select a.subunitate,''F'',left(a.gestiune,@l_stocuri_codgestiune),a.cod,max(a.data),a.cod_intrare,max(a.pret_de_stoc),0,0,0,max(a.data),0,
	max(a.cont_de_stoc),max(a.data_expirarii),0,0,0,0,max(locatie),0, '''', '''', '''', '''', '''', 0, 0, 0, 0, 0, 0, '''', ''01/01/1901''
	from inserted a where a.tip in (''PF'',''CI'',''AF'') and not exists (select cod_intrare from stocuri where subunitate=a.subunitate
	and tip_gestiune=''F'' and cod_gestiune=left(a.gestiune,@l_stocuri_codgestiune) and cod=a.cod and cod_intrare=a.cod_intrare)
	group by a.subunitate,left(a.gestiune,@l_stocuri_codgestiune),a.cod,a.cod_intrare
insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1)
	select a.subunitate,''F'',left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,max(a.data),(case when a.grupa<>'''' then a.grupa else a.cod_intrare end),max(a.pret_de_stoc),0,0,0,
	max(a.data),0,max(a.cont_corespondent),max(a.data_expirarii),0,0,0,0,max(locatie),0, '''', '''', '''', '''', '''', 0, 0, 0, 0, 0, 0, '''', ''01/01/1901''
	from inserted a where a.tip in (''DF'',''PF'')
	and not exists (select cod_intrare from stocuri where subunitate=a.subunitate and tip_gestiune=''F''
	and cod_gestiune=left(a.gestiune_primitoare,@l_stocuri_codgestiune) and cod_intrare=(case when a.grupa<>'''' then a.grupa else a.cod_intrare end) and cod=a.cod)
	group by a.subunitate,left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,(case when a.grupa<>'''' then a.grupa else a.cod_intrare end)
insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1)
	select a.subunitate,''T'',left(a.tert,@l_stocuri_codgestiune),a.cod,max(a.data),a.cod_intrare,max(a.pret_de_stoc),0,0,0,max(a.data),
	0,max(a.cont_corespondent),max(a.data_expirarii),0,0,max(a.tva_neexigibil),max(a.pret_cu_amanuntul),max(locatie),
	isnull(max(a.pret_amanunt_predator),0), '''', '''', '''', '''', '''', 0, 0, 0, 0, 0, 0, '''', ''01/01/1901''
	from inserted a, gestiuni b 
	where a.tip in (''AP'',''AI'') and (@stcust35=1 and left(a.cont_corespondent,2)=''35'' or @stcust8=1 and left(a.cont_corespondent,1)=''8'')
	and a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and b.tip_gestiune not in (''V'', ''I'')
	and not exists (select cod_intrare from stocuri where subunitate=a.subunitate and tip_gestiune=''T'' and cod_gestiune=left(a.tert,@l_stocuri_codgestiune)
	and cod_intrare=a.cod_intrare and cod=a.cod) and a.tip_miscare in (''I'',''E'')
	group by a.subunitate,left(a.tert,@l_stocuri_codgestiune),a.cod,a.cod_intrare

declare @intrari float,@iesiri float,@pret float,@pretam float,@TVAn float,@pretv float,@locm char(9)
declare @csub char(9),@ddata datetime,@cgest char(20),@ccod char(20),@ccodi char(13),@npret float,@npretam float, @nTVAn float,@ddataexp datetime,@ncant float,@tipm char(1),@tipg char(1),@loc char(30),@npretv float,@semn int,@intrare int
declare @gsub char(9),@gtipg char(1),@ggest char(20),@gcod char(20),@gcodi char(13),@gloc char(30),@gdataexp datetime,@gfetch int,@glocm char(9)

declare tmp cursor for
select subunitate, ''F'' as tipg, data, gestiune, cod, cod_intrare, pret_de_stoc, (case when @timbruVaccize=1 then accize_cumparare else (case when  tip_miscare=''E'' then pret_amanunt_predator else pret_cu_amanuntul end) end), cantitate, tip_miscare, locatie, pret_amanunt_predator, TVA_neexigibil, 1, data_expirarii, loc_de_munca
from inserted where @mediup_l=0 and tip in (''PF'',''CI'',''AF'') and tip_miscare in (''I'',''E'')
union all
select subunitate,''F'',data,gestiune_primitoare,cod,(case when grupa<>'''' then grupa else cod_intrare end),pret_de_stoc*(case when tip=''DF'' and procent_vama<>0 then (1-convert(decimal(12,3),procent_vama/100)) else 1 end), pret_cu_amanuntul,cantitate,''I'',locatie,pret_amanunt_predator,TVA_neexigibil,1,data_expirarii, loc_de_munca
from inserted where @mediup_l=0 and tip in (''DF'',''PF'')
union all
select a.subunitate,''T'',data,tert,cod,cod_intrare,pret_de_stoc,0,cantitate,(case when tip_miscare=''E'' then ''I'' else ''E'' end), locatie, 0, 0, 1, data_expirarii, loc_de_munca
from inserted a, gestiuni b where tip in (''AP'',''AI'') and tip_miscare<>''V'' and (@stcust35=1 and left(cont_corespondent,2)=''35'' or @stcust8=1 and left(cont_corespondent,1)=''8'') and a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and b.tip_gestiune not in (''V'', ''I'')
union all
select subunitate,''F'',data,gestiune,cod,cod_intrare,pret_de_stoc,(case when @timbruVaccize=1 then accize_cumparare else (case when  tip_miscare=''E'' then pret_amanunt_predator else pret_cu_amanuntul end) end),cantitate,tip_miscare,locatie, pret_amanunt_predator,TVA_neexigibil,-1,data_expirarii, loc_de_munca
from deleted where @mediup_l=0 and tip in (''PF'',''CI'',''AF'') and tip_miscare in (''I'',''E'')
union all
select subunitate,''F'',data,gestiune_primitoare,cod,(case when grupa<>'''' then grupa else cod_intrare end),pret_de_stoc*(case when tip=''DF'' and procent_vama<>0 then (1-convert(decimal(12,3),procent_vama/100)) else 1 end), pret_cu_amanuntul, cantitate, ''I'', locatie, pret_amanunt_predator, TVA_neexigibil,-1,data_expirarii, loc_de_munca
from deleted where @mediup_l=0 and tip in (''DF'',''PF'')
union all
select a.subunitate,''T'',data,tert,cod,cod_intrare,pret_de_stoc,0,cantitate,(case when tip_miscare=''E'' then ''I'' else ''E'' end), locatie,0,0,-1, data_expirarii, loc_de_munca
from deleted a, gestiuni b where tip in (''AP'',''AI'') and tip_miscare<>''V'' and (@stcust35=1 and left(cont_corespondent,2)=''35'' or @stcust8=1 and left(cont_corespondent,1)=''8'') and a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and b.tip_gestiune not in (''V'', ''I'')
order by subunitate, gestiune, cod, cod_intrare

open tmp
fetch next from tmp into @csub,@tipg,@ddata,@cgest,@ccod,@ccodi,@npret,@npretam,@ncant,@tipm,@loc,@npretv,@nTVAn, @semn,@ddataexp,@locm
set @gsub=@csub
set @gtipg=@tipg
set @ggest=@cgest
set @gcod=@ccod
set @gcodi=@ccodi
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Intrari=0
	set @Iesiri=0
	set @pret=@npret
	set @pretam=@npretam
	set @TVAn=@nTVAn
	set @gloc=''''
	set @glocm=''''
	set @gdataexp=''01/01/1901''
	set @pretv=@npretv
	set @intrare=0
	while @gsub=@csub and @gtipg=@tipg and @ggest=@cgest and @gcod=@ccod and @gcodi=@ccodi
		and @gfetch=0
	begin
		if @tipm=''I'' set @intrari=@intrari+@semn*@ncant
		if @tipm=''E'' set @iesiri=@iesiri+@semn*@ncant
		if @tipm=''I'' and @semn=1 set @intrare=1
		if @tipm=''I'' and @semn=1 set @pret=@npret
		if @tipm=''I'' and @semn=1 set @pretam=@npretam
		if @tipm=''I'' and @semn=1 set @TVAn=@nTVAn
		if @gloc='''' and @tipm=''I'' and @semn=1 and @ncant>0 set @gloc=@loc
		if @glocm='''' and @tipm=''I'' and @semn=1 and @ncant>0 set @glocm=@locm
		if (@gdataexp=''01/01/1901'' or @ddataexp<@gdataexp) and @tipm=''I'' and @semn=1 set @gdataexp=@ddataexp
		if @tipm=''I'' and @semn=1 set @pretv=@npretv
		fetch next from tmp into @csub,@tipg,@ddata,@cgest,@ccod,@ccodi,@npret,@npretam,
			@ncant,@tipm,@loc,@npretv,@nTVAn,@semn,@ddataexp,@locm
                                set @gfetch=@@fetch_status
	end
	update stocuri set intrari=intrari+@intrari,iesiri=iesiri+@iesiri,stoc=stoc+@intrari-@iesiri,
		pret=(case when stoc_initial=0 and @intrare=1 then @pret else pret end),
		locatie=(case when @gloc<>'''' then left(@gloc,@l_stocuri_locatie) else locatie end),
		loc_de_munca=(case when @glocm<>'''' then @glocm else loc_de_munca end),
		data_ultimei_iesiri=(case when data_ultimei_iesiri>@ddata then data_ultimei_iesiri else @ddata end),
		pret_cu_amanuntul=(case when stoc_initial=0 and @intrare=1 then @pretam else pret_cu_amanuntul end),
		TVA_neexigibil=(case when stoc_initial=0 and @intrare=1 then @TVAn else TVA_neexigibil end),
		pret_vanzare=isnull((case when @tipm=''I'' and @intrare=1 then @pretv else pret_vanzare end),0),
		data_expirarii=(case when @gdataexp>''01/01/1901'' and @gdataexp<data_expirarii then @gdataexp else data_expirarii end)
	  where subunitate=@gsub and tip_gestiune=@gtipg and cod_gestiune=left(@ggest,@l_stocuri_codgestiune) and cod=@gcod
		and cod_intrare=@gcodi
	/*delete from stocuri where subunitate=@gsub and cod_gestiune=left(@ggest,@l_stocuri_codgestiune) and cod=@gcod and cod_intrare=@gcodi
		and stoc_initial=0 and intrari=0 and iesiri=0*/
	set @gsub=@csub
	set @gtipg=@tipg
	set @ggest=@cgest
	set @gcod=@ccod
	set @gcodi=@ccodi
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docXinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docXinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docXinc] on [dbo].[pozdoc] for update,insert,delete as
begin 
-- accize dat.
-------------	din tabela par (parametri trimis de Magic):
		declare @timbrulit int, @t_accize int, @agrosem int, @rotunjtnx int, @a_categpro int /** ordinea din Magic:	GC,[GC OR GE],GP,GZ,[GE AND GY]*/
		set @timbrulit=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULIT''),0)
		set @a_categpro=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIZE''),0)
		set @t_accize=@timbrulit
			if (@t_accize=0) set @t_accize=@a_categpro	/**	[GC OR GE]	*/
		set @agrosem=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''AGROSEM''),0)
		set @rotunjtnx=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJTNX''),0)
		if (@a_categpro=1) set @a_categpro=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CATEGPRO''),0)	/**	[GE AND GY]	*/
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,a.tip,a.numar,a.data, 
(case when isnull(n.tip,'''')=''F'' then a.gestiune_primitoare when @agrosem=0 then a.cont_factura else left(a.numar_DVI,13) end), 
(case when @agrosem=0 then left(a.numar_DVI,13) else a.gestiune_primitoare end), 
0,a.valuta,0,0, max((case when isnull(n.tip,'''')=''F'' then ''Amortizare '' when @timbrulit=1 then ''Timbru literar '' when @agrosem=1 then ''Subventii '' else ''Accize '' end)+a.tip+'' ''+rtrim(a.numar)+'' ''+rtrim(a.gestiune)), 
max(a.utilizator),max(a.data_operarii),max(a.ora_operarii),0,a.loc_de_munca,a.comanda,max(a.jurnal)
from inserted a left outer join nomencl n on a.cod=n.cod 
where (@t_accize=1 or isnull(n.tip,'''')=''F'') 
and (a.tip in (''AC'',''AP'') or a.tip=''AE'' and n.tip=''F'')
and (((@a_categpro=0 or isnull(n.tip,'''')<>''F'') and a.accize_cumparare<>0 and a.gestiune_primitoare<>'''') 
or ((@a_categpro=1 or isnull(n.tip,'''')=''F'') and a.accize_datorate<>0 and a.tip in (''AP'', ''AE''))) 
and not exists 
 (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
 and numar_document=a.numar and data=a.data 
and cont_debitor=(case when isnull(n.tip,'''')=''F'' then a.gestiune_primitoare when @agrosem=0 then a.cont_factura else left(a.numar_DVI,13) end) 
and cont_creditor=(case when @agrosem=0 then left(a.numar_DVI,13) else a.gestiune_primitoare end) 
 and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta=a.valuta) 
group by a.subunitate,a.tip,a.numar,a.data,(case when isnull(n.tip,'''')=''F'' then a.gestiune_primitoare when @agrosem=0 then a.cont_factura else left(a.numar_DVI,13) end),(case when @agrosem=0 then left(a.numar_DVI,13) else a.gestiune_primitoare end),a.valuta,a.loc_de_munca,a.comanda
-- dif. pret 308
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data, cont_corespondent,cont_venituri,0,'''',0,0,''Dif. pret'',
max(utilizator),max(data_operarii),max(ora_operarii),0, loc_de_munca,comanda,max(jurnal)
from inserted a where 1=0 and a.tip=''CM'' and a.procent_vama<>0 and not exists 
  (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
  and numar_document=a.numar and data=a.data and cont_debitor=a.cont_corespondent and cont_creditor=a.cont_venituri 
  and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data, a.cont_corespondent,a.cont_venituri,a.loc_de_munca,a.comanda
-- ven AE
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data, (case when cont_corespondent like ''48%'' then cont_corespondent else cont_factura end), cont_venituri,0,'''',0,0, ''Venit'', max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a where a.tip=''AE'' and cont_venituri<>'''' and not exists 
  (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar 
  and data=a.data and cont_debitor=(case when a.cont_corespondent like ''48%'' then a.cont_corespondent else a.cont_factura end) and cont_creditor=cont_venituri and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data, (case when cont_corespondent like ''48%'' then cont_corespondent else cont_factura end), a.cont_venituri,a.loc_de_munca,a.comanda

declare @gvaluta char(3), @valv float, @gcurs float
declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
@gcom char(40), @val float, @gfetch int, @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, @suma float, @sumav float, @valuta char(3), @curs float, @locm char(9), @com char(40)

declare tmp cursor for
select a.subunitate, a.tip as tipdoc, a.numar, a.data, 
(case when isnull(n.tip,'''')=''F'' then a.gestiune_primitoare when @agrosem=0 then a.cont_factura else left(a.numar_DVI,13) end) as contd, 
(case when @agrosem=0 then left(a.numar_DVI,13) else a.gestiune_primitoare end) as contc, 
1, (case when @agrosem=0 and @a_categpro=0 and isnull(n.tip,'''')<>''F'' then round(a.cantitate*a.accize_cumparare,2) else a.accize_datorate end),(case when a.curs<>0 then round(a.accize_datorate/a.curs,2) else 0 end), a.valuta as vlt, a.curs, a.loc_de_munca as loc_munca, a.comanda 
from inserted a left outer join nomencl n on a.cod=n.cod
where (@t_accize=1 or isnull(n.tip,'''')=''F'') and (a.tip in (''AC'',''AP'') or a.tip=''AE'' and n.tip=''F'') and a.gestiune_primitoare<>'''' and (@agrosem=0 and @a_categpro=0 and isnull(n.tip,'''')<>''F'' and a.accize_cumparare<>0 or (@agrosem=1 or @a_categpro=1 or isnull(n.tip,'''')=''F'') and a.accize_datorate<>0) 
union all
select subunitate, tip, numar, data, cont_corespondent, cont_venituri, 
1, round(cantitate*pret_de_stoc*procent_vama/100,2),0,'''',0,loc_de_munca, comanda 
from inserted where 1=0 and tip=''CM'' and procent_vama<>0 
union all
select subunitate, tip, numar, data, (case when cont_corespondent like ''48%'' then cont_corespondent else cont_factura end), cont_venituri, 
1, cantitate*pret_de_stoc+0*(case when cont_corespondent like ''48%'' and pret_amanunt_predator>0 then 1 else 0 end)*cantitate*(pret_amanunt_predator-pret_de_stoc-ROUND(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),0,'''',0, loc_de_munca, comanda 
from inserted where tip=''AE'' and cont_venituri<>'''' 
union all
select a.subunitate, a.tip, a.numar, a.data, (case when isnull(n.tip,'''')=''F'' then a.gestiune_primitoare when @agrosem=0 then a.cont_factura else left(a.numar_DVI,13) end), (case when @agrosem=0 then left(a.numar_DVI,13) else a.gestiune_primitoare end), 
-1, (case when @agrosem=0 and @a_categpro=0 and isnull(n.tip,'''')<>''F'' then round(a.cantitate*a.accize_cumparare,2) else a.accize_datorate end),(case when a.curs<>0 then round(a.accize_datorate/a.curs,2) else 0 end),a.valuta, a.curs, a.loc_de_munca, a.comanda 
from deleted a left outer join nomencl n on a.cod=n.cod
where (@t_accize=1 or isnull(n.tip,'''')=''F'') and (a.tip in (''AC'',''AP'') or a.tip=''AE'' and n.tip=''F'') and a.gestiune_primitoare<>'''' and (@agrosem=0 and @a_categpro=0 and isnull(n.tip,'''')<>''F'' and a.accize_cumparare<>0 or (@agrosem=1 or @a_categpro=1 or isnull(n.tip,'''')=''F'') and a.accize_datorate<>0) 
union all
select subunitate, tip, numar, data, cont_corespondent, cont_venituri, 
-1, round(cantitate*pret_de_stoc*procent_vama/100,2),0,'''',0,loc_de_munca, comanda 
from deleted where 1=0 and tip=''CM'' and procent_vama<>0 
union all
select subunitate, tip, numar, data, (case when cont_corespondent like ''48%'' then cont_corespondent else cont_factura end), cont_venituri,  -1, cantitate*pret_de_stoc+0*(case when cont_corespondent like ''48%'' and pret_amanunt_predator>0 then 1 else 0 end)*cantitate*(pret_amanunt_predator-pret_de_stoc-ROUND(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),0,'''',0, loc_de_munca, comanda 
from deleted where tip=''AE'' and cont_venituri<>'''' 
order by subunitate, tipdoc, numar, data, contd, contc, vlt, loc_munca, comanda

open tmp
fetch next from tmp into @sub,@tip,@numar,@data, @contd,@contc,@semn,@suma,@sumav,@valuta,@curs,@locm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @gvaluta=@valuta
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @gvaluta=@valuta and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @semn=1 set @gcurs=@curs
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @sumav, @valuta, @curs, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+@valv,
		curs=(case when @gvaluta='''' then 0 else @gcurs end)
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata 
	  and cont_debitor=@gctd and cont_creditor=@gctc and valuta=@gvaluta and loc_de_munca=@glm and comanda=@gcom
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and valuta=@gvaluta and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @gvaluta=@valuta
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docTxyinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docTxyinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docTxyinc] on [dbo].[pozdoc] for update,insert,delete as
begin
--TVA nedeductibil pt. receptii
-------------	din tabela par (parametri trimis de Magic):
		declare @cctvaned varchar(13), @contv8 int
		set @cctvaned=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVANED''),''''))
		set @contv8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONTV8''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar, a.data, @cctvaned, max(a.cont_venituri), 0, max(case when b.tert_extern=1 then a.valuta else '''' end), 0, 0, 
''Cheltuieli TVA nedeductibil'', max(a.utilizator), max(a.data_operarii), max(a.ora_operarii), 0, a.loc_de_munca, a.comanda, max(a.jurnal) 
from inserted a, terti b, nomencl n
where @cctvaned<>'''' and a.tip in (''RM'',''RS'') and a.procent_vama=2 and b.subunitate=a.subunitate and b.tert=a.tert and n.cod=a.cod
and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''')
and (@contv8=1 or a.cont_de_stoc not like ''8%'' or n.tip=''F'') 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=@cctvaned and cont_creditor=a.cont_venituri and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta=a.valuta) 
group by a.subunitate, a.tip, a.numar, a.data, a.cont_venituri, a.loc_de_munca, a.comanda, a.valuta

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),
@gcom char(40),@gv char(3),@gcurs float,@val float,@valv float,@gfetch int,@sub char(9),@tip char(2),@nr char(8), @data datetime,@ctd char(13),@ctc char(13),@semn int,@suma float,@sumav float,@vl char(3),@curs float,@lm char(9),@com char(40)

declare tmp cursor for
select a.subunitate, a.tip, a.numar, a.data, @cctvaned as cd, a.cont_venituri as cc, 1, TVA_deductibil, (case when a.valuta<>'''' and b.tert_extern=1 then convert(float,a.grupa) else 0 end), (case when b.tert_extern=1 then a.valuta else '''' end) as valutapoz, (case when b.tert_extern=1 and a.valuta<>'''' then a.curs else 0 end), a.loc_de_munca, a.comanda 
from inserted a, terti b, nomencl n
where @cctvaned<>'''' and a.tip in (''RM'',''RS'') and a.procent_vama=2 and b.subunitate=a.subunitate and b.tert=a.tert and n.cod=a.cod and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') and (@contv8=1 or a.cont_de_stoc not like ''8%'' or n.tip=''F'') 
union all
select a.subunitate, a.tip, a.numar, a.data, @cctvaned as cd, a.cont_venituri as cc, -1, TVA_deductibil, (case when a.valuta<>'''' and b.tert_extern=1 then convert(float,a.grupa) else 0 end), (case when b.tert_extern=1 then a.valuta else '''' end) as valutapoz, (case when b.tert_extern=1 and a.valuta<>'''' then a.curs else 0 end), a.loc_de_munca, a.comanda 
from deleted a, terti b, nomencl n
where @cctvaned<>'''' and a.tip in (''RM'',''RS'') and a.procent_vama=2 and b.subunitate=a.subunitate and b.tert=a.tert and n.cod=a.cod and not (a.tip=''RM'' and a.valuta<>'''' and left(a.numar_DVI, 13)<>'''') and (@contv8=1 or a.cont_de_stoc not like ''8%'' or n.tip=''F'') 
order by a.subunitate, a.tip, a.numar, a.data, cd, cc, a.loc_de_munca, a.comanda, valutapoz

open tmp
fetch next from tmp into @sub, @tip, @nr, @data, @ctd, @ctc, @semn, @suma, @sumav, @vl, @curs, @lm, @com
set @gsub=@sub
set @gtip=@tip
set @gnr=@nr
set @gdata=@data
set @gctd=@ctd
set @gctc=@ctc
set @glm=@lm
set @gcom=@com
set @gv=@vl
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@nr and @gdata=@data and @gctd=@ctd
		and @gctc=@ctc and @glm=@lm and @gcom=@com and @gv=@vl and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @semn=1 and @vl<>'''' set @gcurs=@curs
		fetch next from tmp into @sub, @tip, @nr, @data, @ctd, @ctc, @semn, @suma, @sumav, @vl, @curs, @lm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+(case when @gv='''' then 0 else @valv end),
		curs=(case when @gv='''' then 0 else @gcurs end)
	where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata and
		cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv 
	
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm
		and comanda=@gcom and valuta=@gv and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@nr
	set @gdata=@data
	set @gctd=@ctd
	set @gctc=@ctc
	set @glm=@lm
	set @gcom=@com
	set @gv=@vl
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docTxinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docTxinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docTxinc] on [dbo].[pozdoc] for update,insert,delete as
begin
--rec/av VALUTA
-------------	din tabela par (parametri trimis de Magic):
		declare @cneexrec varchar(13), @cctva varchar(13), @contv8 int, @cdtva varchar(13), @true int, @spunicarmVgenisa int,
				@docpesch_n int, @neexav int
		set @cneexrec=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CNEEXREC''),''''))
		set @cctva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVA''),''''))
		set @contv8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONTV8''),0)
		set @cdtva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CDTVA''),''''))
		set @true=1	/**	parametru setat true in magic*/
		set @spunicarmVgenisa=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''UNICARM''),0)
		if (@spunicarmVgenisa=0) set @spunicarmVgenisa=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''GENISA''),0)
		set @docpesch_n=1-isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0)
		if (@docpesch_n=0)	/**	daca exista parametrul cu val_logica=1:*/
			set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0)
		-- am inlocuit :7=0 or :8=1 din script cu o singura conditie, care nu schimba rezultatul
		set @neexav=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''NEEXAV''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,a.tip,numar,data,max(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else cont_factura end),
max(case when (a.tip=''RS'' or a.tip=''RM'' and left(numar_DVI,13)='''') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when cont_factura like ''418%'' and a.grupa not like ''4428%'' then @cneexrec when (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end), 0, a.valuta,0,0, (case when a.tip=''RS'' and max(a.tert) not in (select tert from terti where tert_extern=1) then max(a.numar_dvi) else ''TVA'' end), max(utilizator), max(data_operarii), max(ora_operarii),0, a.loc_de_munca,comanda, max(jurnal) 
from inserted a, nomencl n 
where n.cod=a.cod and a.tip in (''RM'',''RS'',''AP'',''AS'') and not (a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=2) and a.valuta<>'''' and a.tert in (select tert from terti where tert_extern=1) and (a.tip<>''RM'' or left(a.numar_DVI,13)='''') and (a.cont_de_stoc not like ''8%'' or n.tip=''F'' or @contv8=1) 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else cont_factura end) and cont_creditor=(case when (a.tip=''RS'' or a.tip=''RM'' and left(numar_DVI,13)='''') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when cont_factura like ''418%'' and a.grupa not like ''4428%'' then @cneexrec when (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end) and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta=a.valuta) 
group by a.subunitate,a.tip,a.numar,a.data,(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else cont_factura end),(case when (a.tip=''RS'' or a.tip=''RM'' and left(numar_DVI,13)='''') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when cont_factura like ''418%'' and a.grupa not like ''4428%'' then @cneexrec when (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end),a.loc_de_munca,a.comanda,a.valuta

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,a.tip,numar,data,(case when left(a.tip,1)=''A'' then @cneexrec else cont_de_stoc end ),(case when left(a.tip,1)=''A'' then cont_de_stoc else @cneexrec end), 0, a.valuta,0,0, '''', max(utilizator), max(data_operarii), max(ora_operarii),0, loc_de_munca,comanda, max(jurnal) 
from inserted a where @neexav=0 and a.tip in (''AP'',''AS'',''RM'',''RS'') and not (a.tip in (''AP'',''AS'') 
and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama in (1,2)) 
and not (a.tip=''RM'' and left(numar_DVI,13)='''' and procent_vama=1 or a.tip=''RS'' and procent_vama=1) 
and a.cont_de_stoc in (select cont from conturi where sold_credit=(case when left(a.tip,1)=''A'' 
then 2 else 1 end)) and not exists (select 1 from pozincon where subunitate=a.subunitate 
and tip_document=a.tip and numar_document=a.numar and data=a.data 
and cont_debitor=(case when left(a.tip,1)=''A'' then @cneexrec else a.cont_de_stoc end) 
and cont_creditor=(case when left(a.tip,1)=''A'' then a.cont_de_stoc else @cneexrec end) 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta=a.valuta) 
group by a.subunitate,a.tip,a.numar,a.data,(case when left(a.tip,1)=''A'' then @cneexrec else cont_de_stoc end ),(case when left(a.tip,1)=''A'' then cont_de_stoc else @cneexrec end),a.loc_de_munca,a.comanda,a.valuta

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),
@gcom char(40),@gv char(3),@gcurs float,@val float,@valv float,@gfetch int,@sub char(9),@tip char(2),@nr char(8), @data datetime,@ctd char(13),@ctc char(13),@semn int,@suma float,@sumav float,@vl char(3),@curs float,@lm char(9),@com char(40)

declare tmp cursor for
select subunitate,a.tip,numar,data,(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in 
(''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then 
@cdtva else cont_factura end) as cd, (case when (a.tip=''RS'' or a.tip=''RM'' and left(numar_DVI,13)='''') 
and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when cont_factura like 
''418%'' and a.grupa not like ''4428%'' then @cneexrec when (@true=1 or a.grupa like ''4428%'') 
and a.grupa<>'''' then a.grupa else @cctva end) as cc, 1,TVA_deductibil,(case when a.tip in 
(''RM'',''RS'') then convert(float,a.grupa) else TVA_deductibil/curs end),a.valuta, curs, 
a.loc_de_munca, comanda 
from inserted a, nomencl n
where n.cod=a.cod and a.tip in (''RM'',''RS'',''AP'',''AS'') and not (a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=2) and a.valuta<>'''' and tert in (select tert from terti where tert_extern=1) and (a.tip<>''RM'' or left(numar_DVI,13)='''') and (left(cont_de_stoc,1)<>''8'' or n.tip=''F'' or @contv8=1)
union all
select subunitate,a.tip,numar,data,(case when left(a.tip,1)=''A'' then @cneexrec else cont_de_stoc 
end), (case when left(a.tip,1)=''A'' then cont_de_stoc else @cneexrec end), 1,TVA_deductibil,
(case when a.valuta='''' then 0 when a.tip in (''RM'',''RS'') then convert(float,a.grupa) when curs>0 
then TVA_deductibil/curs else 0 end),a.valuta,curs,a.loc_de_munca,comanda 
from inserted a 
where @neexav=0 and a.tip in (''AP'',''AS'',''RM'',''RS'') and not (a.tip in (''AP'',''AS'') 
and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama in (1,2)) 
and not (a.tip=''RM'' and left(numar_DVI,13)='''' and procent_vama=1 or a.tip=''RS'' and procent_vama=1) 
and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(a.tip,1)=''A'' 
then 2 else 1 end)) 
union all
select subunitate,a.tip,numar,data,(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else cont_factura end), (case when (a.tip=''RS'' or a.tip=''RM'' and left(numar_DVI,13)='''') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when cont_factura like ''418%'' and a.grupa not like ''4428%'' then @cneexrec when (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end), -1,TVA_deductibil,(case when a.tip in (''RM'',''RS'') then convert(float,a.grupa) else TVA_deductibil/curs end),a.valuta,curs, a.loc_de_munca,comanda 
from deleted a, nomencl n
where n.cod=a.cod and a.tip in (''RM'',''RS'',''AP'',''AS'') and not (a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=2) and a.valuta<>'''' and tert in (select tert from terti where tert_extern=1) and (a.tip<>''RM'' or left(numar_DVI,13)='''') and (left(cont_de_stoc,1)<>''8'' or n.tip=''F'' or @contv8=1) 
union all
select subunitate,a.tip,numar,data,(case when left(a.tip,1)=''A'' then @cneexrec else cont_de_stoc 
end), (case when left(a.tip,1)=''A'' then cont_de_stoc else @cneexrec end), -1,TVA_deductibil,
(case when a.valuta='''' then 0 when a.tip in (''RM'',''RS'') then convert(float,a.grupa) when curs>0 
then TVA_deductibil/curs else 0 end),a.valuta,curs,a.loc_de_munca,comanda 
from deleted a
where @neexav=0 and a.tip in (''AP'',''AS'',''RM'',''RS'') and not (a.tip in (''AP'',''AS'') 
and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama in (1,2)) 
and not (a.tip=''RM'' and left(numar_DVI,13)='''' and procent_vama=1 or a.tip=''RS'' and procent_vama=1) 
and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(a.tip,1)=''A'' 
then 2 else 1 end)) 
order by subunitate,a.tip,numar,data,cd,cc,a.loc_de_munca,comanda,a.valuta

open tmp
fetch next from tmp into @sub,@tip,@nr,@data,@ctd,@ctc,@semn,@suma,@sumav,@vl,@curs,@lm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@nr
set @gdata=@data
set @gctd=@ctd
set @gctc=@ctc
set @glm=@lm
set @gcom=@com
set @gv=@vl
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@nr and @gdata=@data and @gctd=@ctd
		and @gctc=@ctc and @glm=@lm and @gcom=@com and @gv=@vl and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @semn=1set @gcurs=@curs
		fetch next from tmp into @sub,@tip,@nr,@data,@ctd,@ctc,@semn,
			@suma,@sumav,@vl,@curs,@lm,@com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val,suma_valuta=suma_valuta+(case when @gv='''' then 0 else @valv end),
		curs=(case when @gv='''' then 0 else @gcurs end)
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata and
	 cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm
		and comanda=@gcom and valuta=@gv and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@nr
	set @gdata=@data
	set @gctd=@ctd
	set @gctc=@ctc
	set @glm=@lm
	set @gcom=@com
	set @gv=@vl
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docTinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docTinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docTinc] on [dbo].[pozdoc] for update,insert,delete as
begin
--TVA rec/av LEI
-------------	din tabela par (parametri trimis de Magic):
		declare @cneexrec varchar(13), @cctva varchar(13), @contv8 int, @cdtva varchar(13), @true int, @spunicarmVgenisa int,
				@docpesch_n int
		set @cneexrec=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CNEEXREC''),''''))
		set @cctva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVA''),''''))
		set @contv8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONTV8''),0)
		set @cdtva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CDTVA''),''''))
		set @true=1	/**	parametru setat true in magic*/
		set @spunicarmVgenisa=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''UNICARM''),0)
		if (@spunicarmVgenisa=0) set @spunicarmVgenisa=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''GENISA''),0)
		set @docpesch_n=1-isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0)
		if (@docpesch_n=0)	/**	daca exista parametrul cu val_logica=1:*/
			set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0)
		-- am inlocuit :7=0 or :8=1 din script cu o singura conditie, care nu schimba rezultatul
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,a.tip,numar,data,max(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else cont_factura end),
max(case when a.tip in (''RM'',''RS'') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when a.tip<>''AC'' and cont_factura like ''418%'' and a.grupa not like ''4428%'' then 
@cneexrec when a.tip<>''AC'' and (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end), 0,'''',0,0, max(case when a.tip=''RS'' and b.tert_extern<>1 then a.numar_dvi else isnull(left(b.denumire,50),'''') end), max(utilizator), max(data_operarii), max(ora_operarii), 0, a.loc_de_munca,comanda, max(jurnal)
from inserted a,terti b,nomencl n 
where b.subunitate=a.subunitate and b.tert=a.tert and n.cod=a.cod and a.tip in (''RM'',''RS'',''AP'',''AS'') and not (a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=2) and not (a.valuta<>'''' and b.tert_extern=1 and (a.tip<>''RM'' or left(a.numar_DVI,13)='''')) and (left(a.cont_de_stoc,1)<>''8'' or n.tip=''F'' or @contv8=1) 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=(case when a.tip in (''RM'',''RS'') then a.cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else a.cont_factura end) and cont_creditor=(case when a.tip in (''RM'',''RS'') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then a.cont_factura when a.tip<>''AC'' and cont_factura like ''418%'' and a.grupa not like ''4428%'' then @cneexrec when a.tip<>''AC'' and (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end) and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,(case when a.tip in (''RM'',''RS'') then cont_venituri when a.tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or a.tip=''AS'') and procent_vama=1 then @cdtva else cont_factura end),(case when a.tip in (''RM'',''RS'') and procent_vama=1 then @cctva when a.tip in (''RM'',''RS'') then cont_factura when a.tip<>''AC'' and cont_factura like ''418%'' and a.grupa not like ''4428%'' then @cneexrec when a.tip<>''AC'' and (@true=1 or a.grupa like ''4428%'') and a.grupa<>'''' then a.grupa else @cctva end), a.loc_de_munca,a.comanda
--AI, AE
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,@cdtva,cont_intermediar,0,'''',0,0,''TVA ded.'',max(utilizator),max(data_operarii),max(ora_operarii),0, loc_de_munca,comanda,max(jurnal)
from inserted a where a.tip=''AI'' and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=@cdtva and cont_creditor=cont_intermediar
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') and (a.Jurnal<>''MFX'' or a.cont_intermediar<>'''') 
group by a.subunitate,a.tip,a.numar,a.data,a.cont_intermediar,a.loc_de_munca,a.comanda
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,cont_factura,@cctva,0,'''',0,0,''TVA colectat'', max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a where a.tip=''AE'' and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=a.cont_factura and cont_creditor=@cctva
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,a.cont_factura,a.loc_de_munca,a.comanda

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),
@gcom char(40),@gv char(3),@gcurs float,@val float,@valv float,@gfetch int,@sub char(9),@tip char(2),@nr char(8), @data datetime,@ctd char(13),@ctc char(13),@semn int,@suma float,@sumav float,@vl char(3),@curs float,@lm char(9),@com char(40)

declare tmp cursor for
select subunitate,tip,numar,data,(case when tip=''AI'' or tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or tip=''AS'') and procent_vama=1 then @cdtva when tip in (''RM'',''RS'') then cont_venituri else cont_factura end) as cd,(case when tip=''AI'' then cont_intermediar when tip in (''RM'',''RS'') and procent_vama=1 then @cctva when tip in (''RM'',''RS'') then cont_factura when left(cont_factura,3)=''418'' and grupa not like ''4428%'' then @cneexrec when (@true=1 or grupa like ''4428%'') and grupa<>'''' then grupa when tip=''AS'' and cont_intermediar<>'''' then cont_intermediar else @cctva end) as cc,1,(case when tip=''RM'' and left(numar_DVI,13)<>'''' then 0 else TVA_deductibil end),0,'''' as vv,0,loc_de_munca,comanda 
from inserted where tip in (''RM'',''RS'',''AP'',''AS'',''AE'',''AI'') and not (tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or tip=''AS'') and procent_vama=2) and not (valuta<>'''' and tert in (select tert from terti where tert_extern=1) and  (tip<>''RM'' or left(numar_DVI,13)=''''))
union all
select subunitate,tip,numar,data,(case when tip=''AI'' or tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or tip=''AS'') and procent_vama=1 then @cdtva when tip in (''RM'',''RS'') then cont_venituri else cont_factura end), (case when tip=''AI'' then cont_intermediar when tip in (''RM'',''RS'') and procent_vama=1 then @cctva when tip in (''RM'',''RS'') then cont_factura when left(cont_factura,3)=''418'' and grupa not like ''4428%'' then @cneexrec when (@true=1 or grupa like ''4428%'') and grupa<>'''' then grupa when tip=''AS'' and cont_intermediar<>'''' then cont_intermediar else @cctva end),-1,(case when tip=''RM'' and left(numar_DVI,13)<>'''' then 0 else TVA_deductibil end),0,'''',0,loc_de_munca,comanda 
from deleted where tip in (''RM'',''RS'',''AP'',''AS'',''AE'',''AI'') and not (tip in (''AP'',''AS'') and @spunicarmVgenisa=0 and (@docpesch_n=1 or tip=''AS'') and procent_vama=2) and not (valuta<>'''' and tert in (select tert from terti where tert_extern=1) and  (tip<>''RM'' or left(numar_DVI,13)=''''))
order by subunitate,tip,numar,data,cd,cc,loc_de_munca,comanda,vv

open tmp
fetch next from tmp into @sub,@tip,@nr,@data,@ctd,@ctc,@semn,@suma,@sumav,@vl,@curs,@lm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@nr
set @gdata=@data
set @gctd=@ctd
set @gctc=@ctc
set @glm=@lm
set @gcom=@com
set @gv=@vl
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@nr and @gdata=@data and @gctd=@ctd
		and @gctc=@ctc and @glm=@lm and @gcom=@com and @gv=@vl and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @semn=1set @gcurs=@curs
		fetch next from tmp into @sub,@tip,@nr,@data,@ctd,@ctc,@semn,
			@suma,@sumav,@vl,@curs,@lm,@com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val,suma_valuta=suma_valuta+(case when @gv='''' then 0 else @valv end),
		curs=(case when @gv='''' then 0 else @gcurs end)
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata and
	 cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm
		and comanda=@gcom and valuta=@gv and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@nr
	set @gdata=@data
	set @gctd=@ctd
	set @gctc=@ctc
	set @glm=@lm
	set @gcom=@com
	set @gv=@vl
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docstoc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docstoc]'))
EXEC dbo.sp_executesql @statement = N'--*** pentru depozit fara pret mediu
create trigger [dbo].[docstoc] on [dbo].[pozdoc] for insert,update,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	--[FW OR FV],DL,FQ,HU,HT,[IF (FR=1,''='',''>'')],CW
	declare @timbruVaccize int, @urmcant2 int, @gestexceptiemediup_l int, @l_stocuri_codgestiune int, @l_stocuri_locatie int, @gestexceptiemediup int, @prestte int  
	set @timbruVaccize=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULIT''),0)
		if (@timbruVaccize=0) set @timbruVaccize=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIZE''),0)
	set @urmcant2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''URMCANT2''),0)
	set @gestexceptiemediup_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MEDIUP''),0)
	set @l_stocuri_codgestiune=isnull((select top 1 syscolumns.length from syscolumns,sysobjects where sysobjects.name=''stocuri'' and 
											sysobjects.id=syscolumns.id and syscolumns.name=''cod_gestiune''),0)
	set @l_stocuri_locatie=isnull((select top 1 syscolumns.length from syscolumns,sysobjects where sysobjects.name=''stocuri'' and 
											sysobjects.id=syscolumns.id and syscolumns.name=''locatie''),0)
	set @gestexceptiemediup=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''MEDIUP''),0)
	set @prestte=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''PRESTTE''),0)
-------------
declare @GestPM char(200)
exec luare_date_par ''GE'', ''MEDIUP'', 0, 0, @GestPM output
set @GestPM='',''+RTrim(@GestPM)+'',''
-- intrari/iesiri
 insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1)
	select a.subunitate,c.tip_gestiune,left(a.gestiune,@l_stocuri_codgestiune),a.cod,min(a.data),a.cod_intrare,max(a.pret_de_stoc),0,0,0,''01/01/1901'',0,
	max(a.cont_de_stoc),max(a.data_expirarii),0,max(case when a.tip=''AI'' and a.discount=1 then 1 else 0 end),
	max(a.tva_neexigibil),max(case when c.tip_gestiune=''A'' and tip_miscare=''I'' then a.pret_cu_amanuntul 
	when c.tip_gestiune=''A'' and tip_miscare=''E'' then a.pret_amanunt_predator else a.accize_cumparare end),
	'''',isnull(max(a.pret_amanunt_predator),0),'''','''','''','''','''',0,0,0,0,0,0,'''',''01/01/1901''
	from inserted a,gestiuni c 
	where (@gestexceptiemediup_l=0 or 
			(@gestexceptiemediup=1 and charindex('',''+rtrim(a.gestiune)+'','',@GestPM)=0 or @gestexceptiemediup<>1 and charindex('',''+rtrim(a.gestiune)+'','',@GestPM)>0)
			or c.tip_gestiune=''A'') and a.tip not in (''PF'',''CI'',''AF'') 
	and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and c.tip_gestiune not in (''V'',''I'')
	and a.tip_miscare in (''I'',''E'') and not exists (select cod_intrare from stocuri where subunitate=a.subunitate
	and tip_gestiune=c.tip_gestiune and cod_gestiune=left(a.gestiune,@l_stocuri_codgestiune) and cod_intrare=a.cod_intrare and cod=a.cod)
	group by a.subunitate,c.tip_gestiune,left(a.gestiune,@l_stocuri_codgestiune),a.cod,a.cod_intrare
 insert into stocuri -- intrari TI
	(Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1)
	select a.subunitate,c.tip_gestiune,left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,min(a.data),
	(case when a.grupa='''' then a.cod_intrare else a.grupa end),max(a.pret_de_stoc),0,0,0,
	max(a.data),0,max(a.cont_corespondent),max(a.data_expirarii),0,max(case when a.discount=1 or
	left(a.cont_de_stoc,3)=''408'' then 1 else 0 end),max(a.tva_neexigibil),max(a.pret_cu_amanuntul),'''',
	isnull(max(a.pret_amanunt_predator),0),'''','''','''','''','''',0,0,0,0,0,0,'''',''01/01/1901''
	from inserted a,gestiuni c 
	where (@gestexceptiemediup_l=0 or 
		(@gestexceptiemediup=1 and charindex('',''+rtrim(a.gestiune_primitoare)+'','',@GestPM)=0 or @gestexceptiemediup<>1 and charindex('',''+rtrim(a.gestiune_primitoare)+'','',@GestPM)>0)
				or c.tip_gestiune=''A'') and a.tip=''TE'' 
	and a.subunitate=c.subunitate and a.gestiune_primitoare=c.cod_gestiune and c.tip_gestiune not in (''V'',''I'')
	and not exists (select cod_intrare from stocuri where subunitate=a.subunitate and tip_gestiune=c.tip_gestiune
	and cod_gestiune=left(a.gestiune_primitoare,@l_stocuri_codgestiune)
	and cod_intrare=(case when a.grupa='''' then a.cod_intrare else a.grupa end) and cod=a.cod)
	group by a.subunitate,c.tip_gestiune,left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,
	(case when a.grupa='''' then a.cod_intrare else a.grupa end)

declare @intrari float,@iesiri float,@int2 float,@ies2 float,@pret float,@pretam float,@TVAn float,@pretv float
declare @csub char(9),@ddat datetime,@cgest char(20),@ccod char(20),@ccodi char(13),@npret float,@npretam float,@nTVAn float,@ddataexp datetime,@ncant float,@ncant2 float,@tipm char(1),@tipg char(1),@loc char(30),@npretv float,@semn int,@intrare int,@ccontstoc char(13),@com char(40),@cntr char(20),@furn char(13),@lot char(13)
declare @gsub char(9),@gtipg char(1),@ggest char(20),@gcod char(20),@gcodi char(13),@gloc char(30),@gfetch int,@gctstoc char(13),@gdata datetime,@ggdat datetime,@ddataulties datetime,@gdataexp datetime,@gcom char(40),@gcntr char(20),@gfurn char(13),@glot char(13)

declare tmp cursor for
select a.subunitate as sub,c.tip_gestiune,data,gestiune,cod,cod_intrare,pret_de_stoc,(case when @timbruVaccize=1 then accize_cumparare else (case when tip_miscare=''E'' then pret_amanunt_predator else pret_cu_amanuntul end) end),cantitate,(case when tip=''RM'' and numar_DVI<>'''' then accize_datorate else suprataxe_vama end),tip_miscare,locatie,pret_amanunt_predator,TVA_neexigibil,1 as semn,data_expirarii,a.cont_de_stoc,comanda,(case when tip=''TE'' then factura when tip in (''AP'',''AC'',''PP'') then contract else '''' end),(case tip when ''RM'' then tert when ''AI'' then cont_venituri else '''' end),(case when tip=''RM'' then cont_corespondent when tip in (''PP'',''AI'') then grupa else '''' end)
from inserted a,gestiuni c where a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and (@gestexceptiemediup_l=0 or 
	(@gestexceptiemediup=1 and charindex('',''+rtrim(gestiune)+'','',@GestPM)=0 or @gestexceptiemediup<>1 and charindex('',''+rtrim(gestiune)+'','',@GestPM)>0) 
		or c.tip_gestiune=''A'') and tip not in (''PF'',''CI'',''AF'') and tip_miscare in (''I'',''E'')
union all
select a.subunitate,c.tip_gestiune,a.data,gestiune_primitoare,a.cod,(case when grupa<>'''' then grupa else a.cod_intrare end),(case when @prestte=1 and accize_datorate <> 0 then accize_datorate else pret_de_stoc end),a.pret_cu_amanuntul,cantitate,suprataxe_vama,''I'',a.locatie,pret_amanunt_predator,a.TVA_neexigibil,1,a.data_expirarii,a.cont_corespondent,a.comanda,factura,isnull(s.furnizor,''''),isnull(s.lot,'''')
from inserted a
inner join gestiuni c on a.subunitate=c.subunitate and a.gestiune_primitoare=c.cod_gestiune
inner join gestiuni b on a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune
left outer join stocuri s on a.subunitate=s.subunitate and s.tip_gestiune=b.tip_gestiune and s.cod_gestiune=a.gestiune and s.cod=a.cod and s.cod_intrare=a.cod_intrare
where a.tip=''TE'' and (@gestexceptiemediup_l=0 or 
	(@gestexceptiemediup=1 and charindex('',''+rtrim(gestiune_primitoare)+'','',@GestPM)=0 or @gestexceptiemediup<>1 and charindex('',''+rtrim(gestiune_primitoare)+'','',@GestPM)>0)
	or c.tip_gestiune=''A'')
union all
select a.subunitate,c.tip_gestiune,data,gestiune,cod,cod_intrare,pret_de_stoc,(case when @timbruVaccize=1 then accize_cumparare else (case when tip_miscare=''E'' then pret_amanunt_predator else pret_cu_amanuntul end) end),cantitate,(case when tip=''RM'' and numar_DVI<>'''' then accize_datorate else suprataxe_vama end),tip_miscare,locatie,pret_amanunt_predator,TVA_neexigibil,-1,data_expirarii,'''',comanda,(case when tip=''TE'' then factura when tip in (''AP'',''AC'',''PP'') then contract else '''' end),(case tip when ''RM'' then tert when ''AI'' then cont_venituri else '''' end),(case when tip=''RM'' then cont_corespondent when tip in (''PP'',''AI'') then grupa else '''' end)
from deleted a,gestiuni c where a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and (@gestexceptiemediup_l=0 or 
	(@gestexceptiemediup=1 and charindex('',''+rtrim(gestiune)+'','',@GestPM)=0 or @gestexceptiemediup<>1 and charindex('',''+rtrim(gestiune)+'','',@GestPM)>0)
	or c.tip_gestiune=''A'') and tip not in (''PF'',''CI'',''AF'') and tip_miscare in (''I'',''E'')
union all
select a.subunitate,c.tip_gestiune,data,gestiune_primitoare,cod,(case when grupa<>'''' then grupa else cod_intrare end),pret_de_stoc,pret_cu_amanuntul,cantitate,suprataxe_vama,''I'',locatie,pret_amanunt_predator,TVA_neexigibil,-1,data_expirarii,'''',comanda,factura,'''',''''
from deleted a,gestiuni c where a.subunitate=c.subunitate and a.gestiune_primitoare=c.cod_gestiune and (@gestexceptiemediup_l=0 or
	(@gestexceptiemediup=1 and charindex('',''+rtrim(gestiune_primitoare)+'','',@GestPM)=0 or @gestexceptiemediup<>1 and charindex('',''+rtrim(gestiune_primitoare)+'','',@GestPM)>0)
	or c.tip_gestiune=''A'') and tip=''TE''
order by sub,gestiune,cod,cod_intrare,semn

open tmp
fetch next from tmp into @csub,@tipg,@ddat,@cgest,@ccod,@ccodi,@npret,@npretam,@ncant,@ncant2,@tipm,@loc,@npretv,@nTVAn,@semn,@ddataexp,@ccontstoc,@com,@cntr,@furn,@lot
set @gsub=@csub
set @gtipg=@tipg
set @ggest=@cgest
set @gcod=@ccod
set @gcodi=@ccodi
set @ggdat=@ddat
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Intrari=0
	set @Iesiri=0
	set @int2=0
	set @ies2=0
	set @pret=@npret
	set @pretam=@npretam
	set @TVAn=@nTVAn
	set @gloc=''''
	set @gcom=''''
	set @gcntr=''''
	set @gfurn=''''
	set @glot=''''
	set @pretv=@npretv
	set @intrare=0
	set @gctstoc=''''
	set @ddataulties=''01/01/1901''
	set @gdata=''01/01/1901''
	set @gdataexp=''01/01/1901''
	set @ggdat=@ddat
	while @gsub=@csub and @gtipg=@tipg and @ggest=@cgest and @gcod=@ccod and @gcodi=@ccodi
		and @gfetch=0
	begin
		if @tipm=''I'' and @semn=1 set @intrare=1
		if (@gdata=''01/01/1901'' or @ddat<@gdata) and @intrare=1 set @gdata=@ddat
		if (@gdataexp=''01/01/1901'' or @ddataexp<@gdataexp) and @intrare=1 set @gdataexp=@ddataexp
		if @tipm=''I'' set @intrari=@intrari+@semn*@ncant
		if @tipm=''E'' set @iesiri=@iesiri+@semn*@ncant
		if @urmcant2=1 
		begin
			if @tipm=''I'' set @int2=@int2+@semn*@ncant2
			if @tipm=''E'' set @ies2=@ies2+@semn*@ncant2
		end
		if @intrare=1 
		begin 
			set @pret=@npret
			set @pretam=@npretam
			set @TVAn=@nTVAn
			set @ggdat=@ddat
		end
		if @gloc='''' and @intrare=1 and @ncant>0 set @gloc=@loc
		if @gcom='''' and @intrare=1 and @ncant>0 set @gcom=@com
		if @gcntr='''' and @intrare=1 and @ncant>0 set @gcntr=@cntr
		if @gfurn='''' and @intrare=1 and @ncant>0 set @gfurn=@furn
		if @glot='''' and @intrare=1 and @ncant>0 set @glot=@lot
		if @intrare=1 and @ddat<=@gdata set @gctstoc=@ccontstoc
		if @tipm=''E'' and @semn=1 and @ddataulties<@ddat set @ddataulties=@ddat
		if @intrare=1 set @pretv=@npretv
		fetch next from tmp into @csub,@tipg,@ddat,@cgest,@ccod,@ccodi,@npret,@npretam,
			@ncant,@ncant2,@tipm,@loc,@npretv,@nTVAn,@semn,@ddataexp,@ccontstoc,@com,@cntr,@furn,@lot
		set @gfetch=@@fetch_status
	end
	update stocuri set intrari=intrari+@intrari,iesiri=iesiri+@iesiri,
			stoc=stoc+@intrari-@iesiri,
			intrari_UM2=intrari_UM2+@int2,iesiri_UM2=iesiri_UM2+@ies2,stoc_UM2=stoc_UM2+@int2-@ies2,
			pret=(case when stoc_initial=0 and @intrare=1 then @pret else pret end),
			locatie=(case when @gloc<>'''' then left(@gloc,@l_stocuri_locatie) else locatie end),
			comanda=(case when @gcom<>'''' then @gcom else comanda end),
			contract=(case when @gcntr<>'''' then @gcntr else contract end),
			furnizor=(case when @gfurn<>'''' then @gfurn else furnizor end),
			lot=(case when @glot<>'''' then @glot else lot end),
			data_ultimei_iesiri=(case when data_ultimei_iesiri>@ddataulties then data_ultimei_iesiri else @ddataulties end),
			pret_cu_amanuntul=(case when stoc_initial=0 and @intrare=1 then @pretam else pret_cu_amanuntul end),
			TVA_neexigibil=(case when stoc_initial=0 and @intrare=1 then @TVAn else TVA_neexigibil end),
			pret_vanzare=isnull((case when @tipm=''I'' and @intrare=1 then @pretv else pret_vanzare end),0),
			data_expirarii=(case when @gdataexp>''01/01/1901'' and @gdataexp>data_expirarii then @gdataexp else data_expirarii end),
			cont=(case when @gctstoc<>'''' and @gdata<=data then @gctstoc else cont end),
			data=(case when @tipm=''I'' and @ggdat<data then @ggdat else data end)
		 where subunitate=@gsub and tip_gestiune=@gtipg and cod_gestiune=left(@ggest,@l_stocuri_codgestiune) and cod=@gcod
			and cod_intrare=@gcodi
	set @gsub=@csub
	set @gtipg=@tipg
	set @ggest=@cgest
	set @gcod=@ccod
	set @gcodi=@ccodi
	set @ggdat=@ddat
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docRinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docRinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docRinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-- receptii fara valuta
-------------	din tabela par (parametri trimis de Magic):
	declare @rotunjr_n int, @bugetari int, @timbrulit int, @inv44 int
	set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJR'' and val_logica=1),2)
	set @bugetari=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''BUGETARI''),0)
	set @timbrulit=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULIT''),0)
		if (@timbrulit=0) set @timbrulit=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULT2''),0)
	set @inv44=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''INV44''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal) 
select a.subunitate, tip, numar, data, (case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_factura when tip=''RM'' and @bugetari=1 and 1=0 and cont_intermediar<>'''' then cont_venituri else cont_de_stoc end), 
(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_de_stoc else cont_factura end),0,'''',0,0,'''', max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,max(case when /*@bugetari*/0=0 or cont_intermediar<>'''' or cont_de_stoc like ''6%'' or tip=''RS'' then comanda else '''' end), max(jurnal)
from inserted a 
left join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_de_stoc
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert
where a.tip in (''RM'',''RS'') and not(a.tip in (''RM'',''RS'') and a.valuta<>'''' and isnull(tert_extern,0)=1) and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=(case when a.tip_miscare=''V'' and (a.cont_de_stoc like ''7%'' or @inv44=1 and a.cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then a.cont_factura when a.tip=''RM'' and @bugetari=1 and 1=0 and a.cont_intermediar<>'''' then a.cont_venituri else a.cont_de_stoc end) and cont_creditor=(case when a.tip_miscare=''V'' and (a.cont_de_stoc like ''7%'' or @inv44=1 and a.cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then a.cont_de_stoc else a.cont_factura end) and loc_de_munca=a.loc_de_munca and comanda=(case when /*@bugetari*/0=0 or a.cont_intermediar<>'''' or cont_de_stoc like ''6%'' or a.tip=''RS'' then a.comanda else '''' end)) 
group by a.subunitate,a.tip,a.numar,a.data,(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_factura when tip=''RM'' and @bugetari=1 and 1=0 and cont_intermediar<>'''' then cont_venituri else cont_de_stoc end), (case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_de_stoc else cont_factura end), a.loc_de_munca,a.comanda
-- receptii in valuta
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_factura else cont_de_stoc end),(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_de_stoc else cont_factura end),0,valuta,0,0,'''', max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a 
left join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_de_stoc
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert
where a.tip in (''RM'',''RS'') and a.valuta<>'''' and isnull(t.tert_extern,0)=1 and (a.tip=''RS'' or  rtrim(left(a.numar_DVI,13))='''') 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_factura else cont_de_stoc end) and cont_creditor=(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_de_stoc else cont_factura end) and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta=a.valuta) 
group by a.subunitate,a.tip,a.numar,a.data,(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_factura else cont_de_stoc end), (case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then cont_de_stoc else cont_factura end),a.loc_de_munca,a.comanda,a.valuta

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),
@gcom char(40),@gvaluta char(3),@gexpl char(30),@val float,@valv float,@gcurs float,@gfetch int, @sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int,@cant float,@pretv float,@disc float,@prets float,@valuta char(3),@curs float,@locm char(9),@com char(40),@expl char(30),@conti char(13),@invers int,@cota float

declare tmp cursor for
select a.subunitate,tip,numar,data,cont_de_stoc as contd, cont_factura as contc, 1, cantitate, pret_valuta -(case when @timbrulit=1 and tip=''RM'' then accize_cumparare else 0 end),discount, pret_de_stoc, (case when valuta<>'''' and isnull(t.tert_extern,0)=1 then valuta else '''' end) as vv, curs, loc_de_munca, (case when /*@bugetari*/0=0 or cont_intermediar<>'''' or cont_de_stoc like ''6%'' or tip=''RS'' then comanda else '''' end) as cc, (case when tip=''RS'' and isnull(tert_extern,0)=0 then numar_dvi else isnull(t.denumire,'''') end),(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then -1 else 1 end),a.cota_TVA
from inserted a
left join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_de_stoc
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert
where tip in (''RM'',''RS'') 
union all
select a.subunitate,tip,numar,data, cont_de_stoc as contd, cont_factura as contc,-1, cantitate, pret_valuta -(case when @timbrulit=1 and tip=''RM'' then accize_cumparare else 0 end),discount, pret_de_stoc, (case when valuta<>'''' and isnull(t.tert_extern,0)=1 then valuta else '''' end), curs, loc_de_munca, (case when /*@bugetari*/0=0 or cont_intermediar<>'''' or cont_de_stoc like ''6%'' or tip=''RS'' then comanda else '''' end), (case when tip=''RS'' and isnull(tert_extern,0)=0 then numar_dvi else isnull(t.denumire,'''') end),(case when tip_miscare=''V'' and (cont_de_stoc like ''7%'' or @inv44=1 and cont_de_stoc like ''44%'' or cont_de_stoc like ''6%'' /*and cantitate<0*/ and isnull(c.tip_cont,'''')=''P'') then -1 else 1 end),a.cota_TVA
from deleted a
left join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_de_stoc
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert
where tip in (''RM'',''RS'') and not (valuta<>'''' and isnull(t.tert_extern,0)=1 and tip=''RM'' and rtrim(left(numar_DVI,13))<>'''')
order by 1,2,3,4,5,6,14,15,12

open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@cant,@pretv,@disc,@prets,@valuta,@curs,@locm,@com,@expl,@invers,@cota
if @invers=-1
begin
	set @conti=@contd set @contd=@contc set @contc=@conti
end
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gvaluta=@valuta
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	set @gexpl=@expl
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gvaluta=@valuta and @gfetch=0
	begin
		set @disc=(case when abs(@disc+@cota*100/(@cota+100))<0.01 then convert(decimal(12,4),-@cota*100/(@cota+100)) else convert(decimal(12,4),@disc) end)		
		if @valuta='''' set @val=@val+round(convert(decimal(18,5),@cant*round(@pretv*(case when @curs=0 then 1 else @curs end)* 
			(1+@disc/100),5)),@rotunjr_n)*@semn*@invers
		else set @val=@val+round(convert(decimal(18,5),@cant*round(@pretv*@curs*(1+@disc/100),5)),@rotunjr_n)*@semn*@invers
		set @valv=@valv+@cant*@pretv*(1+@disc/100)*@semn*@invers
		if @semn=1 set @gcurs=@curs
		if @semn=1 set @gexpl=@expl
		fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,
			@cant,@pretv,@disc,@prets,@valuta,@curs,@locm,@com,@expl,@invers,@cota
		set @gfetch=@@fetch_status
		if @invers=-1
		begin
			set @conti=@contd set @contd=@contc set @contc=@conti
		end
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+(case when @gvaluta='''' then 0 else @valv end), 
		curs=(case when @gvaluta='''' then 0 else @gcurs end), explicatii=isNull(@gexpl,@gtip+'' ''+@gnr)
	where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and valuta=@gvaluta
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and valuta=@gvaluta and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gvaluta=@valuta
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docNinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docNinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docNinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-------------	din tabela par (parametri trimis de Magic):
		declare @modatim int, @bugetari int, @timbrult2 int, @orto int, @cont348_l int
		set @modatim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MODATIM''),0)
		set @bugetari=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''BUGETARI''),0)
		set @timbrult2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULT2''),0)
		set @orto=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''ORTO''),0)
		set @cont348_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONT348''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data, (case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_de_stoc when @orto=1 and @cont348_l=1 and left(cont_de_stoc,2) in (''33'',''34'') then cont_corespondent else cont_intermediar end), (case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_intermediar else cont_de_stoc end),0,'''',0,0, 
max(tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)+'' ''+rtrim(tert)+'' ''+rtrim(factura)), max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a where not (a.tip=''TE'' and @timbrult2=1) and not(a.tip=''AC'' and @modatim=1) and a.tip in (''CM'',''AE'',''AP'',''AC'',''TE'',''CI'') and not (a.tip=''AP'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) and a.cont_intermediar<>'''' and a.cont_intermediar<>a.cont_de_stoc 
and a.tip_miscare<>''V'' and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
and numar_document=a.numar and data=a.data and cont_debitor=(case when a.tip=''TE'' and left(a.cont_de_stoc,3)<>''345'' then a.cont_de_stoc when @orto=1 and @cont348_l=1 and left(cont_de_stoc,2) in (''33'',''34'') then cont_corespondent else a.cont_intermediar end) and cont_creditor=(case when tip=''TE'' and left(a.cont_de_stoc,3)<>''345'' then a.cont_intermediar else a.cont_de_stoc end) 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_de_stoc when @orto=1 and @cont348_l=1 and left(cont_de_stoc,2) in (''33'',''34'') then cont_corespondent else cont_intermediar end),
(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_intermediar else cont_de_stoc end),a.loc_de_munca,a.comanda

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,cont_intermediar,cont_corespondent,0,'''',0,0, 
max(tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)+'' ''+rtrim(tert)+'' ''+rtrim(factura)), max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a where @orto=1 and @cont348_l=1 and a.tip=''AP'' and left(a.cont_de_stoc,2) in (''33'',''34'') and a.cont_intermediar<>'''' and a.cont_intermediar<>a.cont_de_stoc 
and a.tip_miscare<>''V'' and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
and numar_document=a.numar and data=a.data and cont_debitor=a.cont_intermediar and cont_creditor=a.cont_corespondent 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,cont_intermediar, cont_corespondent,a.loc_de_munca,a.comanda

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,cont_de_stoc,cont_intermediar,0,'''',0,0,max(tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)+'' ''+rtrim(tert)+'' ''+rtrim(factura)),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,'''',max(jurnal)
from inserted a where @bugetari=1 and 1=0 and a.tip=''RM'' and a.cont_intermediar<>'''' and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=a.cont_de_stoc and cont_creditor=a.cont_intermediar 
and loc_de_munca=a.loc_de_munca and comanda='''' and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,a.cont_de_stoc,a.cont_intermediar,a.loc_de_munca

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),
@gcom char(40),@gvaluta char(3),@gexpl char(30),@val float,@valv float,@gcurs float,@gfetch int
declare @sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int,
@cant float,@pretv float,@disc float,@prets float,@valuta char(3),@curs float,@locm char(9),@com char(40),@expl char(30) 

declare tmp cursor for
select subunitate,tip,numar,data,(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_de_stoc when @orto=1 and @cont348_l=1 and left(cont_de_stoc,2) in (''33'',''34'') then cont_corespondent else cont_intermediar end) as contd,
(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_intermediar else cont_de_stoc end) as contc,1,cantitate,0,0,(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then -1 else 1 end)*pret_de_stoc,'''' as vv,0,loc_de_munca,comanda,(case when tip=''AP'' then (select denumire from terti where subunitate=inserted.subunitate and tert=inserted.tert) else (select denumire from nomencl where cod=inserted.cod) end) 
from inserted where not (tip=''TE'' and @timbrult2=1) and not(tip=''AC'' and @modatim=1) and cont_intermediar<>'''' and cont_intermediar<>cont_de_stoc and not (tip=''AP'' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) and tip_miscare<>''V'' and tip in (''CM'',''AE'',''AP'',''AC'',''TE'',''CI'')
union all
select subunitate,tip,numar,data,cont_intermediar as contd,cont_corespondent as contc,
1,cantitate,0,0,pret_vanzare,'''' as vv,0,loc_de_munca,comanda,(case when tip=''AP'' then (select denumire from terti where subunitate=inserted.subunitate and tert=inserted.tert) else (select denumire from nomencl where cod=inserted.cod) end) 
from inserted where @orto=1 and @cont348_l=1 and tip=''AP'' and left(cont_de_stoc,2) in (''33'',''34'') and cont_intermediar<>'''' and cont_intermediar<>cont_de_stoc and tip_miscare<>''V'' 
union all
select subunitate,tip,numar,data,cont_de_stoc,cont_intermediar,1,cantitate,0,0,pret_valuta+TVA_deductibil/cantitate,'''',0, loc_de_munca,'''',(select denumire from terti where subunitate=inserted.subunitate and tert=inserted.tert) 
from inserted where @bugetari=1 and 1=0 and tip=''RM'' and cont_intermediar<>'''' 
union all
select subunitate,tip,numar,data,(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_de_stoc when @orto=1 and @cont348_l=1 and left(cont_de_stoc,2) in (''33'',''34'') then cont_corespondent else cont_intermediar end) as contd,
(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then cont_intermediar else cont_de_stoc end) as contc,-1,cantitate,0,0,(case when tip=''TE'' and left(cont_de_stoc,3)<>''345'' then -1 else 1 end)*pret_de_stoc,'''',0,loc_de_munca,comanda,(case when tip=''AP'' then (select denumire from terti where subunitate=deleted.subunitate and tert=deleted.tert) else (select denumire from nomencl where cod=deleted.cod) end)  
from deleted where not (tip=''TE'' and @timbrult2=1) and not(tip=''AC'' and @modatim=1) and cont_intermediar<>'''' and cont_intermediar<>cont_de_stoc and not (tip=''AP'' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) and tip_miscare<>''V'' and tip in (''CM'',''AE'',''AP'',''AC'',''TE'',''CI'') 
union all
select subunitate,tip,numar,data,cont_intermediar as contd,cont_corespondent as contc,-1,cantitate,0,0,pret_vanzare,'''',0,loc_de_munca,comanda,(case when tip=''AP'' then (select denumire from terti where subunitate=deleted.subunitate and tert=deleted.tert) else (select denumire from nomencl where cod=deleted.cod) end)  
from deleted where @orto=1 and @cont348_l=1 and tip=''AP'' and left(cont_de_stoc,2) in (''33'',''34'') and cont_intermediar<>'''' and cont_intermediar<>cont_de_stoc and tip_miscare<>''V'' 
union all
select subunitate,tip,numar,data,cont_de_stoc,cont_intermediar,1,cantitate,0,0,-(pret_valuta+TVA_deductibil/cantitate),'''',0, loc_de_munca,'''',(select denumire from terti where subunitate=deleted.subunitate and tert=deleted.tert) 
from deleted where @bugetari=1 and 1=0 and tip=''RM'' and cont_intermediar<>'''' 
order by subunitate,tip,numar,data,contd,contc,loc_de_munca,comanda,vv

open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@cant,@pretv,@disc,@prets,
	@valuta,@curs,@locm,@com,@expl
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gvaluta=@valuta
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	set @gexpl=@expl
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gvaluta=@valuta and @gfetch=0
	begin
	set @val=@val+round(convert(decimal(17,5),@cant*@prets*@semn),2)
	set @valv=@valv+@cant*@pretv*@semn
	if @semn=1set @gcurs=@curs
	if @semn=1set @gexpl=@expl
	fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,
			@cant,@pretv,@disc,@prets,@valuta,@curs,@locm,@com,@expl
	set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+(case when @gvaluta='''' then 0 else @valv end), 
		curs=(case when @gvaluta='''' then 0 else @gcurs end), explicatii=isNull(@gexpl,@gtip+'' ''+@gnr)
	where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and valuta=@gvaluta
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and valuta=@gvaluta and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gvaluta=@valuta
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docMinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docMinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docMinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-------------	din tabela par (parametri trimis de Magic):
declare @inverscmp int, @cont348_l int, @faradesc int, @modatim int, @timbrult2 int, @pasmatex int, @nuctegal int, @dif345 int,
		@nucpfegal int, @inversAmReev int 
set @inverscmp=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''INVERSCMP''),0)
set @cont348_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONT348''),0)
set @faradesc=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''FARADESC''),0)
set @modatim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MODATIM''),0)
set @timbrult2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULT2''),0)
set @pasmatex=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''PASMATEX''),0)
set @nuctegal=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''NUCTEGAL''),0)
set @dif345=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DIF345''),0)
set @nucpfegal=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''NUCPFEGAL''),0)
set @inversAmReev=isnull((select top 1 val_logica from par where tip_parametru=''MF'' and parametru=''INVCTREEV''),0)		
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, numar, data, 
(case when a.tip=''AE'' and cont_corespondent like ''48%'' and cont_venituri<>'''' then cont_factura 
	when tip_miscare=''E'' or tip_miscare=''V'' and n.tip=''F'' and a.tip in (''AE'',''AP'') or a.tip=''AI'' 
	and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 
	then cont_corespondent else cont_de_stoc end), 
(case when (tip_miscare=''I'' or tip_miscare=''V'' and a.tip=''AI'' and n.tip=''F'') and not (a.tip=''AI'' and n.tip=''F'' and 
	a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0) or a.tip=''AI'' and 
	n.tip=''R'' then cont_corespondent 
	when cont_intermediar='''' or @timbrult2=1 
	or a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then cont_de_stoc 
	else cont_intermediar end),
0,(case when a.tip in (''AI'',''AE'') then a.valuta else '''' end),0,0,max(a.tip+'' ''+rtrim(a.gestiune)+'' ''+rtrim(tert)+'' ''+rtrim(factura)), max(utilizator),max(data_operarii),max(ora_operarii),0,a.loc_de_munca,comanda,max(jurnal)
from inserted a, nomencl n 
where a.cod=n.cod 
and (@faradesc=0 
or not (a.tip<>''TE'' and tip_miscare=''E'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A''))) 
and a.tip not in (''DF'',''RM'') and not(a.tip=''AC'' and @modatim=1) and not (a.tip=''CM'' and left(a.cont_de_stoc,2)=''34'' and @inverscmp=1) 
and (a.tip=''AI'' and n.tip=''R'' or tip_miscare=''V'' and n.tip=''F'' or a.tip_miscare<>''V'')
/*and not (a.tip=''AP'' and a.cont_de_stoc like ''8%'' and (a.valuta<>'''' and a.tert in (select tert from terti where tert_extern=1)))*/ 
and not (a.tip=''AP'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and not (a.tip=''PF'' and @nucpfegal=1 and cont_corespondent=cont_de_stoc)
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=
(case when a.tip=''AE'' and cont_corespondent like ''48%'' and cont_venituri<>'''' then cont_factura 
	when tip_miscare=''E'' or tip_miscare=''V'' and n.tip=''F'' and a.tip in (''AE'',''AP'') or a.tip=''AI'' 
	and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 
	then cont_corespondent else cont_de_stoc end) 
and cont_creditor=
(case when (tip_miscare=''I'' or tip_miscare=''V'' and a.tip=''AI'' and n.tip=''F'') and not (a.tip=''AI'' and n.tip=''F'' and 
	a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0) or a.tip=''AI'' and 
	n.tip=''R'' then cont_corespondent 
	when cont_intermediar='''' or @timbrult2=1 
	or a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then cont_de_stoc 
	else cont_intermediar end)
and loc_de_munca=a.loc_de_munca and comanda=a.comanda) 
group by a.subunitate,a.tip,a.numar,a.data,a.loc_de_munca,a.comanda,(case when a.tip in (''AI'',''AE'') then a.valuta else '''' end),
(case when a.tip=''AE'' and cont_corespondent like ''48%'' and cont_venituri<>'''' then cont_factura 
	when tip_miscare=''E'' or tip_miscare=''V'' and n.tip=''F'' and a.tip in (''AE'',''AP'') or a.tip=''AI'' 
	and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 
	then cont_corespondent else cont_de_stoc end), 
(case when (tip_miscare=''I'' or tip_miscare=''V'' and a.tip=''AI'' and n.tip=''F'') and not (a.tip=''AI'' and n.tip=''F'' and 
	a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0) or a.tip=''AI'' and 
	n.tip=''R'' then cont_corespondent 
	when cont_intermediar='''' or @timbrult2=1 
	or a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then cont_de_stoc 
	else cont_intermediar end)

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,cont_de_stoc,cont_corespondent,0,'''',0,0,max(tip+'' ''+rtrim(gestiune)),
max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a where tip=''CM'' and left(cont_de_stoc,2)=''34'' and @inverscmp=1 and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=a.cont_de_stoc and cont_creditor=a.cont_corespondent 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,a.cont_corespondent,a.cont_de_stoc,a.loc_de_munca,a.comanda

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),
@gcom char(40),@gexpl char(30),@gvaluta char(3),@valuta char(3),@val float,@valv float,@curs float,@gcurs float,@gfetch int, @sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int,@cant float,@pretv float,@disc float,@prets float,@locm char(9),@com char(40),@expl char(30) 

declare tmp cursor for
select subunitate,a.tip,numar,data,
(case when a.tip=''AE'' and cont_corespondent like ''48%'' and cont_venituri<>'''' then cont_factura 
	when tip_miscare=''E'' or tip_miscare=''V'' and n.tip=''F'' and a.tip in (''AE'',''AP'') or a.tip=''AI'' 
	and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 
	then cont_corespondent else cont_de_stoc end) as contd,
(case when (tip_miscare=''I'' or tip_miscare=''V'' and a.tip=''AI'' and n.tip=''F'') and not (a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0) or a.tip=''AI'' and n.tip=''R'' then cont_corespondent 
	when cont_intermediar='''' or @timbrult2=1 
	or a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then cont_de_stoc 
	else cont_intermediar end) as contc,
(case when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then -1 else 1 end),
cantitate,pret_valuta,discount,
(case when a.tip=''AP'' and (left(cont_de_stoc,2) in (''33'',''34'') or @modatim=0 and cont_de_stoc like ''35%'') and @cont348_l=1 and @pasmatex=0 and @dif345=0 then a.pret_vanzare 
when subunitate+gestiune_primitoare in (select subunitate+cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) and (a.tip=''TE'' and tert like ''348%'' and (a.valuta<>'''' or 1=1) 
	or a.tip=''AP'' and @modatim=1 and cont_de_stoc like ''354%'') 
	or (@cont348_l=1 and a.tip=''AI'' and cont_de_stoc like ''371%'' and @modatim=1) then pret_amanunt_predator 
when subunitate+gestiune_primitoare in (select subunitate+cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) and @modatim=1 and a.tip=''TE'' and cont_corespondent like ''357%'' then a.pret_cu_amanuntul 
when @cont348_l=1 and a.tip=''AC'' and cont_de_stoc like ''371%'' and 1=0 then suprataxe_vama 
else pret_de_stoc-(case when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cantitate*a.accize_datorate else 0 end) end),
a.loc_de_munca,comanda,left((case when a.tip in (''AI'',''AE'') and left(a.factura,8)+a.Contract<>'''' 
then left(a.factura,8)+a.Contract when a.tip=''AP'' then (select denumire from terti where 
subunitate=a.subunitate and tert=a.tert) else n.denumire end),50),(case when a.tip in (''AI'',''AE'') 
then a.valuta else '''' end),curs
FROM inserted a, nomencl n where a.cod=n.cod and a.tip not in (''DF'',''RM'') and (a.tip=''AI'' and 
n.tip=''R'' or tip_miscare=''V'' and n.tip=''F'' or a.tip_miscare<>''V'') and not(a.tip=''AC'' and @modatim=1) 
and not (a.tip=''AP'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and not (a.tip=''PF'' and @nucpfegal=1 and cont_corespondent=cont_de_stoc)
and not (a.tip=''CM'' and cont_de_stoc like ''34%'' and @inverscmp=1)
/*and not (tip=''AP'' and cont_de_stoc like ''8%'' and (valuta<>'''' and tert in (select tert from terti where tert_extern=1)))*/ 
union all
select subunitate,a.tip,numar,data,cont_de_stoc as contd,
cont_corespondent as contc,
-1,cantitate,pret_valuta,discount,pret_de_stoc,
a.loc_de_munca,comanda,left(n.denumire,50),'''',curs
FROM inserted a, nomencl n where a.cod=n.cod and a.tip=''CM'' and cont_de_stoc like ''34%'' and @inverscmp=1
union all
select subunitate,a.tip,numar,data,
(case when a.tip=''AE'' and cont_corespondent like ''48%'' and cont_venituri<>'''' then cont_factura 
	when tip_miscare=''E'' or tip_miscare=''V'' and n.tip=''F'' and a.tip in (''AE'',''AP'') or a.tip=''AI'' 
	and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 
	then cont_corespondent else cont_de_stoc end) as contd,
(case when (tip_miscare=''I'' or tip_miscare=''V'' and a.tip=''AI'' and n.tip=''F'') and not (a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0) or a.tip=''AI'' and n.tip=''R'' then cont_corespondent 
	when cont_intermediar='''' or @timbrult2=1 
	or a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then cont_de_stoc 
	else cont_intermediar end) as contc,
(case when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=0 and a.cantitate<0 then 1 else -1 end),
cantitate,pret_valuta,discount,
(case when a.tip=''AP'' and (left(cont_de_stoc,2) in (''33'',''34'') or @modatim=0 and cont_de_stoc like ''35%'') and @cont348_l=1 and @pasmatex=0 and @dif345=0 then a.pret_vanzare 
when subunitate+gestiune_primitoare in (select subunitate+cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) and (a.tip=''TE'' and tert like ''348%'' and (a.valuta<>'''' or 1=1) 
	or a.tip=''AP'' and @modatim=1 and cont_de_stoc like ''354%'') 
	or (@cont348_l=1 and a.tip=''AI'' and cont_de_stoc like ''371%'' and @modatim=1) then pret_amanunt_predator 
when subunitate+gestiune_primitoare in (select subunitate+cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) and @modatim=1 and a.tip=''TE'' and cont_corespondent like ''357%'' then a.pret_cu_amanuntul 
when @cont348_l=1 and a.tip=''AC'' and cont_de_stoc like ''371%'' and 1=0 then suprataxe_vama 
else pret_de_stoc-(case when a.tip=''AI'' and n.tip=''F'' and a.jurnal=''MFX'' and a.factura=''MRE'' and @inversAmReev=1 then a.cantitate*a.accize_datorate else 0 end) end),
a.loc_de_munca,comanda,'''',(case when a.tip in (''AI'',''AE'') then a.valuta else '''' end),curs
FROM deleted a, nomencl n where a.cod=n.cod and a.tip not in (''DF'',''RM'') and (a.tip=''AI'' and 
n.tip=''R'' or tip_miscare=''V'' and n.tip=''F'' or a.tip_miscare<>''V'') and not(a.tip=''AC'' and @modatim=1) 
and not (a.tip=''AP'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and not (a.tip=''PF'' and @nucpfegal=1 and cont_corespondent=cont_de_stoc)
and not (a.tip=''CM'' and cont_de_stoc like ''34%'' and @inverscmp=1)
/*and not (tip=''AP'' and cont_de_stoc like ''8%'' and (valuta<>'''' and tert in (select tert from terti where tert_extern=1)))*/ 
union all
select subunitate,a.tip,numar,data,cont_de_stoc as contd,
cont_corespondent as contc,
1,cantitate,pret_valuta,discount,pret_de_stoc,
a.loc_de_munca,comanda,left(n.denumire,50),'''',curs
FROM deleted a, nomencl n 
where a.cod=n.cod and a.tip=''CM'' and cont_de_stoc like ''34%'' and @inverscmp=1
order by subunitate,a.tip,numar,data,contd,contc,a.loc_de_munca,comanda

open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@cant,@pretv,@disc,@prets,@locm,
	@com,@expl,@valuta,@curs
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gvaluta=@valuta
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gexpl=@expl
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gvaluta=@valuta and @gfetch=0
	begin
		set @val=@val+round(convert(decimal(17,5),@cant*@prets*@semn),2)
		set @valv=@valv+@cant*@pretv*@semn
		if @semn=1 set @gexpl=@expl
		if @semn=1 set @gcurs=@curs
		fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,
				@cant,@pretv,@disc,@prets,@locm,@com,@expl,@valuta,@curs
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+(case when @gvaluta='''' then 0 else @valv end),
		curs=(case when @gvaluta='''' then 0 else @gcurs end),explicatii=isNull(@gexpl,@gtip+'' ''+@gnr)
		where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and valuta=@gvaluta
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and valuta=@gvaluta and suma=0 and suma_valuta=0
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and cont_debitor=cont_creditor and tip_document=''TE'' and @nuctegal=1
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gvaluta=@valuta
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [doclunastc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[doclunastc]'))
EXEC dbo.sp_executesql @statement = N'create trigger [dbo].[doclunastc] on [dbo].[pozdoc] for update, insert, delete as
declare @nlunastoc int, @nanulstoc int, @ddatastoc datetime
set @nlunastoc= (select val_numerica from par where tip_parametru=''GE'' and parametru=''LUNAINC'')
set @nanulstoc= (select val_numerica from par where tip_parametru=''GE'' and parametru=''ANULINC'')
set @dDatastoc=dateadd(month,1,convert(datetime,str(@nLunastoc,2)+''/01/''+str(@nAnulstoc,4)))
if (select count(*) from inserted where data<@dDatastoc)>0 or (select count(*) from deleted where data<@dDatastoc)>0
begin
	RAISERROR (''Violare integritate date. Incercare de modificare luna inchisa / stocuri (pozDOC).'', 16, 1)
	rollback transaction
end'
GO
/****** Object:  Trigger [docFxinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docFxinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docFxinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-------------	din tabela par (parametri trimis de Magic):
		declare @rotunj int, @metchim int, @discsep int, @contdisc_a varchar(13),@contdisc_l int, @stcust35 int, @stcust8 int, @invdiscap int
		set @rotunj=isnull((select top 1 Val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJ'' and val_logica=1),2)
		set @metchim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''METCHIM''),0)
		set @discsep=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DISCSEP''),0)
		set @contdisc_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CONTDISC''),''''))
		set @contdisc_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONTDISC''),0)
		set @stcust35=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STCUST35''),0)
		set @stcust8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STCUST8''),0)
		set @invdiscap=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''INVDISCAP''),0)
-------------
/*insert into pozincon 
select a.subunitate, tip, numar, data, '''', cont_de_stoc, 0, '''', 0, 0, isnull(max(b.denumire),''''),
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, terti b where a.tip=''AP'' and a.cont_de_stoc like ''8%'' and b.subunitate=a.subunitate and b.tert=a.tert and a.valuta<>'''' and a.tert in (select tert from terti where tert_extern=1) 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip 
and numar_document=a.numar and data=a.data and cont_debitor='''' and cont_creditor=a.cont_de_stoc 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, a.cont_de_stoc, a.loc_de_munca, a.comanda*/
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, tip, numar, data, cont_venituri, cont_venituri, 0, '''', 0, 0, isNull(max(left(t.denumire,50)),''''), 
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, terti t where @metchim=1 and a.tip in (''AP'',''AS'') and left(a.cont_venituri,1)=''6'' and t.subunitate=a.subunitate and t.tert=a.tert and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=a.cont_venituri and cont_creditor=a.cont_venituri and loc_de_munca=a.loc_de_munca and comanda=a.comanda) 
group by a.subunitate, a.tip, a.numar, a.data, a.cont_venituri, a.loc_de_munca, a.comanda
--union all
INSERT into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,@contdisc_a+(case when @contdisc_l=0 then '''' 
else ''.''+a.gestiune end),cont_factura,0,MAX((case when isnull(t.tert_extern,0)=1 then a.valuta 
else '''' end)),max((case when isnull(t.tert_extern,0)=1 then a.Curs else 0 end)),0, IsNull(max(left(t.denumire,50)),''''),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
FROM inserted a, terti t WHERE @discsep=1 and a.tip in (''AP'',''AS'') and not (@stcust35=1 and left(a.cont_corespondent, 2)=''35'' or @stcust8=1 and left(a.cont_corespondent, 1)=''8'') and t.subunitate=a.subunitate and t.tert=a.tert
and not exists (select 1 from pozincon where subunitate=a.subunitate and  tip_document=a.tip 
and numar_document=a.numar and data=a.data and cont_debitor=@contdisc_a+(case when @contdisc_l=0 
then '''' else ''.''+a.gestiune end) and cont_creditor=a.cont_factura and loc_de_munca=a.loc_de_munca 
and comanda=a.comanda and valuta=(case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end))
GROUP BY a.subunitate,a.tip,a.numar,a.data,@contdisc_a+(case when @contdisc_l=0 then '''' 
else ''.''+a.gestiune end), a.cont_factura, a.loc_de_munca, a.comanda, 
(case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end)

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), 
@gctc char(13), @glm char(9), @gcom char(40), @gvaluta char(3), @gcurs float, @val float, 
@valv float, @gfetch int
declare @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), 
@contc char(13), @semn int, @suma float, /*@sumav float, */@locm char(9), @com char(40), 
@valuta char(3), @curs float

declare tmp cursor for
/*select subunitate, tip, numar, data, '''' as contd, cont_de_stoc as contc, 1, cantitate*pret_de_stoc, loc_de_munca, comanda, space(3) as valuta, 0
from inserted where tip in (''AP'',''AS'') and cont_de_stoc like ''8%'' 
union all*/
select subunitate, tip, numar, data, cont_venituri as contd, cont_venituri as contc, -1, round(cantitate*pret_vanzare,@rotunj), loc_de_munca, comanda, space(3) as valuta, 0
from inserted where @metchim=1 and tip in (''AP'',''AS'') and left(cont_venituri,1)=''6'' 
union all
select a.subunitate,tip,numar,data,@contdisc_a+(case when @contdisc_l=0 then '''' else ''.''+gestiune 
end), cont_factura,1, round(cantitate*pret_valuta*(case when valuta='''' then 1 else curs end)*
round(convert(decimal(17,5), (case when @invdiscap=0 then discount else (1.00-100.00/(100.00+
discount))*100.00 end)), 2)/100,@rotunj), loc_de_munca, comanda, 
(case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end), 
(case when isnull(t.tert_extern,0)=1 then a.curs else 0 end)
from inserted a
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert 
where tip in (''AP'',''AS'') and @discsep=1 and not (@stcust35=1 and left(cont_corespondent, 2)=''35'' or @stcust8=1 and left(cont_corespondent, 1)=''8'') 
union all
/*select subunitate, tip, numar, data, '''', cont_de_stoc, -1, cantitate*pret_de_stoc, loc_de_munca, comanda, space(3), 0
from deleted where tip in (''AP'',''AS'') and cont_de_stoc like ''8%'' 
union all*/
select subunitate, tip, numar, data, cont_venituri, cont_venituri, 1, round(cantitate*pret_vanzare,@rotunj), loc_de_munca, comanda, space(3), 0
from deleted where @metchim=1 and tip in (''AP'',''AS'') and left(cont_venituri,1)=''6'' 
union all
select a.subunitate,tip,numar,data,@contdisc_a+(case when @contdisc_l=0 then '''' else ''.''+gestiune 
end), cont_factura,-1,round(cantitate*pret_valuta*(case when valuta='''' then 1 else curs end)*
round(convert(decimal(17,5), (case when @invdiscap=0 then discount else (1.00-100.00/(100.00+
discount))*100.00 end)), 2)/100,@rotunj), loc_de_munca, comanda, 
(case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end), 
(case when isnull(t.tert_extern,0)=1 then a.curs else 0 end)
from deleted a
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert 
where tip in (''AP'',''AS'') and @discsep=1 and not (@stcust35=1 and left(cont_corespondent, 2)=''35'' or @stcust8=1 and left(cont_corespondent, 1)=''8'') 
order by subunitate, tip, numar, data, contd, contc, loc_de_munca, comanda, valuta

open tmp
fetch next from tmp into @sub,@tip,@numar,@data, @contd,@contc,@semn,@suma,@locm,@com,@valuta,@curs
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gvaluta=@valuta
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gvaluta=@valuta and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+(case when @curs=0 then 0 else 
			round(convert(decimal(17,5),@suma*@semn/@curs),	@rotunj) end)
		if @semn=1 set @gcurs=@curs
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn, @suma, @locm, 
			@com, @valuta, @curs
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val, 
		suma_valuta=suma_valuta+(case when @gvaluta='''' then 0 else @valv end),
		curs=(case when @gvaluta='''' then 0 else @gcurs end)
		where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and valuta=@gvaluta 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and valuta=@gvaluta and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gvaluta=@valuta
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docFinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docFinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docFinc] on [dbo].[pozdoc] for update,insert,delete as
begin 
-------------	din tabela par (parametri trimis de Magic):
		declare @rotunj int, @metchim int, @contv8 int, @discsep int, @comppret int, @accize int, @stcust35 int, @stcust8 int
		set @rotunj=isnull((select top 1 Val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJ'' and val_logica=1),2)
		set @metchim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''METCHIM''),0)
		set @contv8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONTV8''),0)
		set @discsep=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DISCSEP''),0)
		set @comppret=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''COMPPRET''),0)
		set @accize=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIZE''),0)
			if (@accize=0) set @accize=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULIT''),0)
		set @stcust35=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STCUST35''),0)
		set @stcust8=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STCUST8''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, numar, data, max(case when @metchim=0 and tip_miscare=''V'' and cont_venituri like ''6%'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then cont_venituri else cont_factura end), max(case when @metchim=0 and tip_miscare=''V'' and cont_venituri like ''6%'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then cont_factura else cont_venituri end), 
0, max(case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end), max(case when isnull(t.tert_extern,0)=1 then a.curs else 0 end), 0, max(isnull(left(t.denumire,50),'''')), max(utilizator), max(data_operarii), max(ora_operarii), 0, a.loc_de_munca, comanda,max(jurnal)
from inserted a
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert 
left join nomencl n on n.cod=a.cod
left join conturi cv on cv.subunitate=a.subunitate and cv.cont=a.cont_venituri 
where a.tip in (''AP'',''AS'') and (left(a.cont_de_stoc,1)<>''8'' or isnull(n.tip,'''')=''F'' or @contv8=1) 
and not exists (select 1 from pozincon 
	where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data 
	and cont_debitor=(case when @metchim=0 and a.tip_miscare=''V'' and a.cont_venituri like ''6%'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then a.cont_venituri else a.cont_factura end) 
	and cont_creditor=(case when @metchim=0 and a.tip_miscare=''V'' and a.cont_venituri like ''6%'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then a.cont_factura else a.cont_venituri end) 
	and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta=(case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end)) 
group by a.subunitate, a.tip, a.numar, a.data, a.cont_factura, a.cont_venituri, a.loc_de_munca, a.comanda

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
 @gcom char(40), @gvaluta char(3), @val float,@valv float, @gcurs float, @gfetch int, @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, 
 @suma float, @sumav float, @valuta char(3), @curs float, @locm char(9), @com char(40), @insdel char(1)

declare tmp cursor for
select a.subunitate, a.tip, numar, data, (case when @metchim=0 and tip_miscare=''V'' and left(cont_venituri,1)=''6'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then cont_venituri else cont_factura end) as contd, (case when @metchim=0 and tip_miscare=''V'' and left(cont_venituri,1)=''6'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then cont_factura else cont_venituri end) as contc, (case when @metchim=0 and tip_miscare=''V'' and left(cont_venituri,1)=''6'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then -1 else 1 end), (case when @discsep=1 and not (@stcust35=1 and left(a.cont_corespondent, 2)=''35'' or @stcust8=1 and left(a.cont_corespondent, 1)=''8'') then round(convert(decimal(17,5),cantitate*(case when a.valuta='''' then pret_valuta else round(curs*pret_valuta,5) end)),@rotunj) else round(convert(decimal(17,5),cantitate*(a.pret_vanzare-(case when @accize=1 then accize_datorate else 0 end))),@rotunj) end), round(convert(decimal(17,5),cantitate*((case when a.valuta<>'''' and curs<>0 then pret_valuta-(case when @accize=1 then (accize_datorate/curs) else 0 end) else pret_valuta end)*(1-(case when @discsep=1 then 0 else discount end)/100)+@comppret*(case when isnull(n.tip,'''')=''F'' then 0 else 1 end)*suprataxe_vama/1000)),3), (case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end) as vv, (case when isnull(t.tert_extern,0)=1 then a.curs else 0 end), a.loc_de_munca, comanda, ''I''
from inserted a
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert 
left join nomencl n on n.cod=a.cod
left join conturi cv on cv.subunitate=a.subunitate and cv.cont=a.cont_venituri 
where a.tip in (''AP'',''AS'') and (left(cont_de_stoc,1)<>''8'' or isnull(n.tip,'''')=''F'' or @contv8=1)
union all
select a.subunitate, a.tip, numar, data, (case when @metchim=0 and tip_miscare=''V'' and left(cont_venituri,1)=''6'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then cont_venituri else cont_factura end), (case when @metchim=0 and tip_miscare=''V'' and left(cont_venituri,1)=''6'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then cont_factura else cont_venituri end), (case when @metchim=0 and tip_miscare=''V'' and left(cont_venituri,1)=''6'' or /*a.cantitate<0 and*/ a.cont_venituri like ''7%'' and isnull(cv.tip_cont,'''')=''A'' then 1 else -1 end), (case when @discsep=1 and not (@stcust35=1 and left(a.cont_corespondent, 2)=''35'' or @stcust8=1 and left(a.cont_corespondent, 1)=''8'') then round(convert(decimal(17,5),cantitate*(case when a.valuta='''' then pret_valuta else round(curs*pret_valuta,5) end)),@rotunj) else round(convert(decimal(17,5),cantitate*(a.pret_vanzare-(case when @accize=1 then accize_datorate else 0 end))),@rotunj) end), round(convert(decimal(17,5),cantitate*((case when a.valuta<>'''' and curs<>0 then pret_valuta-(case when @accize=1 then (accize_datorate/curs) else 0 end) else pret_valuta end)*(1-(case when @discsep=1 then 0 else discount end)/100)+@comppret*(case when isnull(n.tip,'''')=''F'' then 0 else 1 end)*suprataxe_vama/1000)),3), (case when isnull(t.tert_extern,0)=1 then a.valuta else '''' end) as vv, (case when isnull(t.tert_extern,0)=1 then a.curs else 0 end), a.loc_de_munca, comanda, ''D''
from deleted a
left join terti t on t.subunitate=a.subunitate and t.tert=a.tert 
left join nomencl n on n.cod=a.cod
left join conturi cv on cv.subunitate=a.subunitate and cv.cont=a.cont_venituri 
where a.tip in (''AP'',''AS'') and (left(cont_de_stoc,1)<>''8'' or isnull(n.tip,'''')=''F'' or @contv8=1)
order by 1, 2, 3, 4, 5, 6, 12, 13, 10

open tmp
fetch next from tmp into @sub,@tip,@numar,@data, @contd,@contc,@semn,@suma,@sumav, @valuta,@curs,@locm,@com,@insdel
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gvaluta=@valuta
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gvaluta=@valuta and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @insdel=''I'' set @gcurs=@curs
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @sumav, @valuta, @curs, @locm, @com, @insdel
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val, suma_valuta=suma_valuta+(case when @gvaluta='''' then 0 else @valv end), 
		curs=(case when @gvaluta='''' then 0 else @gcurs end) 
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom and valuta=@gvaluta 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gvaluta=@valuta
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docfacav]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docfacav]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docfacav] on [dbo].[pozdoc] for update,insert,delete with append as
begin
--avansuri avize/receptii
-------------	din tabela par (parametri trimis de Magic):
	declare @spgenisaVunicarm int, @docpesch_n int, @neexav int
	set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''GENISA''),0)
		if (@spgenisaVunicarm=0) set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''UNICARM''),0)
	set @docpesch_n=(case isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0) when 1 then 0 else 1 end)
		if (@docpesch_n=0) set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0)
		--	sau "val_logica=0 or val_numerica=1" in loc de "@docpesch_n=1" mai jos
	set @neexav=(case isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''NEEXAV''),0) when 1 then 0 else 1 end)
-------------
insert into facturi select subunitate,max(loc_de_munca),(case when left(tip,1)=''A'' then 0x46 else 0x54 end),
(case when cod_intrare='''' then ''AVANS'' else cod_intrare end),tert,max(data_facturii),max(data_scadentei),0,0,0,max(valuta),max(curs),0,0,0,max(cont_de_stoc),0,0,max(comanda),
max(data) from inserted where tip in (''AP'',''AS'',''RM'',''RS'') and (case when cod_intrare='''' then ''AVANS'' else cod_intrare end) not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when left(inserted.tip,1)=''A'' then 0x46 else 0x54 end))
and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(tip,1)=''A'' then 2 else 1 end)) 
group by subunitate,(case when left(tip,1)=''A'' then 0x46 else 0x54 end),tert,(case when cod_intrare='''' then ''AVANS'' else cod_intrare end) 

declare @contF char(13),@gvaluta char(3),@gcurs float,@glocm char(9),@gcom char(40)
declare @csub char(9),@ctip char(2),@ctert char(13),@cfactura char(20),@semn int,@valuta char(3),
	@curs float,@cont char(13),@df datetime,@ds datetime,@locm char(9),@com char(40),@ach float,@achv float,
	@achitat float,@achitatv float
declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@gdf datetime,@gds datetime,@tipf binary,@gfetch int

declare tmp cursor for
select subunitate,tip,tert,(case when cod_intrare='''' then ''AVANS'' else cod_intrare end) as facturaav,1,valuta,curs,cont_de_stoc,data_facturii,data_scadentei,loc_de_munca,comanda,(case when left(tip,1)=''A'' then round(convert(decimal(17,5),cantitate*pret_vanzare),2)+@neexav*(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip=''AS'') then 0 else 1 end)*tva_deductibil else round(convert(decimal(17,5),cantitate*round(convert(decimal(18,5),pret_valuta*(case when valuta<>'''' then curs else 1 end)),5)),2)+round(convert(decimal(17,5),@neexav*(case when tip=''RM'' and left(numar_dvi,13)='''' and procent_vama=1 then 0 else 1 end)*tva_deductibil),2) end),(case when valuta<>'''' and curs>0 then (case when left(tip,1)=''A'' then round(convert(decimal(17,5),cantitate*pret_valuta*(1-discount/100)),2)+round(convert(decimal(17,5),@neexav*(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip=''AS'') then 0 else 1 end)*tva_deductibil/curs),2) else round(convert(decimal(17,5),cantitate*pret_valuta),2)+round(convert(decimal(17,5),@neexav*(case when tip=''RM'' and left(numar_dvi,13)='''' and procent_vama=1 then 0 else 1 end)*tva_deductibil/curs),2) end) else 0 end)
from inserted where tip in (''AP'',''AS'',''RM'',''RS'') and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(tip,1)=''A'' then 2 else 1 end)) 
union all
select subunitate,tip,tert,(case when cod_intrare='''' then ''AVANS'' else cod_intrare end) as facturaav,-1,valuta,curs,cont_de_stoc,data_facturii,data_scadentei,loc_de_munca,comanda,(case when left(tip,1)=''A'' then round(convert(decimal(17,5),cantitate*pret_vanzare),2) +@neexav*(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip=''AS'') then 0 else 1 end)*tva_deductibil else round(convert(decimal(17,5),cantitate*round(convert(decimal(18,5),pret_valuta*(case when valuta<>'''' then curs else 1 end)),5)),2)+round(convert(decimal(17,5),@neexav*(case when tip=''RM'' and left(numar_dvi,13)='''' and procent_vama=1 then 0 else 1 end)*tva_deductibil),2) end),(case when valuta<>'''' and curs>0 then (case when left(tip,1)=''A'' then round(convert(decimal(17,5),cantitate*pret_valuta*(1-discount/100)),2)+round(convert(decimal(17,5),@neexav*(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip=''AS'') then 0 else 1 end)*tva_deductibil/curs),2) else round(convert(decimal(17,5),cantitate*pret_valuta),2)+round(convert(decimal(17,5),@neexav*(case when tip=''RM'' and left(numar_dvi,13)='''' and procent_vama=1 then 0 else 1 end)*tva_deductibil/curs),2) end) else 0 end)
from deleted where tip in (''AP'',''AS'',''RM'',''RS'') and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(tip,1)=''A'' then 2 else 1 end)) 
order by subunitate,tip,tert,facturaav

open tmp
fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@valuta,@curs,@cont,@df,@ds,@locm,@com,@ach,@achv
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @Achitat=0
set @AchitatV=0
set @ContF=@cont
set @gvaluta=@valuta
set @gcurs=@curs
set @gdf=@df
set @gds=@ds
set @glocm=@locm
set @gcom=@com
while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
begin
	if @ctip in (''RM'',''RP'',''RQ'',''RS'')
	begin		
		set @tipf=0x54
		set @Achitat=@Achitat+@semn*@ach
		if @valuta<>'''' 
			set @achitatv=@achitatv+@semn*@achv
	end
	else begin
		set @tipf=0x46
		set @Achitat=@Achitat+@semn*@ach
		if @valuta<>''''
			set @achitatv=@achitatv+@semn*@achv
	end
	if @semn=1 set @contF=@cont
	if @semn=1 set @gvaluta=@valuta
	if @semn=1 set @gcurs=@curs
	if @semn=1 set @gdf=@df
	if @semn=1 set @gds=@ds
	if @semn=1 set @glocm=@locm
	if @semn=1 set @gcom=@com

fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@valuta,@curs,@cont,@df,@ds,@locm,@com,@ach,@achv
set @gfetch=@@fetch_status
end
update facturi set achitat=achitat+@achitat,sold=sold-@achitat,
	valuta='''',curs=0,
	cont_de_tert=@contF,loc_de_munca=@glocm,comanda=@gcom,
	data=(case when data>@gdf then @gdf else data end),data_scadentei=(case when data_scadentei>@gds then @gds else data_scadentei end)
where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura

update facturi set achitat_valuta=achitat_valuta+@achitatv,sold_valuta=sold_valuta-@achitatv,
	valuta=@gvaluta,curs=@gcurs 
from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura
	and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1 

set @gtert=@ctert
set @gsub=@csub
set @gfactura=@cfactura
set @gtip=@ctip
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docfac]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docfac]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docfac] on [dbo].[pozdoc] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
--(8)		[IF (FK,FL,2)],	[IF (FO,FP,2)], FV, GC, HA, [HM OR HL], HN, HO
	declare @rotunj_n int, @rotunjr_n int, @timbrulit int, @factbil int, @stoehr int, @spgenisaVunicarm int, @docpesch_n int
	set @rotunj_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJ'' and val_logica=1),2)
	set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJR'' and val_logica=1),2)
	set @timbrulit=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULIT''),0)
	set @factbil=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''FACTBIL''),0)
	set @stoehr=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''STOEHR''),0)
	set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''GENISA''),0)
		if (@spgenisaVunicarm=0) set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''UNICARM''),0)
	set @docpesch_n=(case isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0) when 1 then 0 else 1 end)
		if (@docpesch_n=0) set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''DOCPESCH''),0)
		--	sau "val_logica=0 or val_numerica=1" in loc de "@docpesch_n=1" mai jos
-------------
insert into facturi select subunitate,max(loc_de_munca),(case when tip in (''AP'',''AS'') then 0x46 else 0x54 end),factura,tert,max(data_facturii),max(data_scadentei),0,0,0,max(valuta),max(curs),0,0,0,max(cont_factura),0,0,max(comanda),
max(data_facturii) from inserted where tip in (''RM'',''RP'',''RQ'',''RS'',''AP'',''AS'') and factura not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when inserted.tip in (''AP'',''AS'') then 0x46 else 0x54 end))
and ((cont_factura<>'''' or left(cont_de_stoc,1)<>''8'' or @factbil=1 and cont_factura='''')) group by subunitate,(case when tip in (''AP'',''AS'') then 0x46 else 0x54 end),tert,factura

declare @Valoare float,@Tva float,@Tva9 float,@valoarev float,@contF char(13),@gvaluta char(3),@gcurs float,@glocm char(9),@gcom char(40)
declare @csub char(9),@ctip char(2),@ctert char(13),@cfactura char(20),@semn int,@tvad float,@cant float,@valuta char(3),
	@curs float,@pstoc float,@pval float,@pvanz float,@cota float,@disc float,@cont char(13),@dvi char(8),
	@df datetime,@ds datetime,@LME float,@locm char(9),@com char(40),@TVAv float,@dfTVA int,@cuTVA int
declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@gdf datetime,@gds datetime,@tipf binary,@gfetch int

declare tmp cursor for
select subunitate,tip,tert,factura,1,tva_deductibil,cantitate,valuta,curs,pret_de_stoc,pret_valuta-(case when tip in (''RM'',''RS'') and @timbrulit=1 and numar_dvi='''' then accize_cumparare else 0 end),(case when 1=0 and left(cont_de_stoc,1)=''8'' and not (tip=''AP'' and @factbil=1) then pret_de_stoc else pret_vanzare end),cota_tva,discount,(case when 1=0 and tip=''AP'' and cont_de_stoc like ''8%'' and @factbil=0 then '''' else cont_factura end),numar_DVI,data_facturii,data_scadentei,suprataxe_vama,loc_de_munca,comanda,(case when isnumeric(grupa)=1 then convert(float,grupa) else 0 end),procent_vama
from inserted where tip in (''RM'',''RP'',''RQ'',''RS'',''AP'',''AS'') and ((cont_factura<>'''' or left(cont_de_stoc,1)<>''8'' or @factbil=1 and cont_factura='''')) 
union all
select subunitate,tip,tert,factura,-1,tva_deductibil,cantitate,valuta,curs,pret_de_stoc,pret_valuta-(case when tip in (''RM'',''RS'') and @timbrulit=1 and numar_dvi='''' then accize_cumparare else 0 end),(case when 1=0 and left(cont_de_stoc,1)=''8'' and not (tip=''AP'' and @factbil=1) then pret_de_stoc else pret_vanzare end),cota_tva,discount,(case when 1=0 and tip=''AP'' and cont_de_stoc like ''8%'' and @factbil=0 then '''' else cont_factura end),numar_DVI,data_facturii,data_scadentei,suprataxe_vama,loc_de_munca,comanda,(case when isnumeric(grupa)=1 then convert(float,grupa) else 0 end),procent_vama
from deleted where tip in (''RM'',''RP'',''RQ'',''RS'',''AP'',''AS'') and ((cont_factura<>'''' or left(cont_de_stoc,1)<>''8'' or @factbil=1 and cont_factura='''')) 
order by subunitate,tip,tert,factura

open tmp
fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@tvad,@cant,@valuta,@curs,@pstoc,@pval,@pvanz,@cota,@disc,@cont,@dvi,@df,@ds,@LME,@locm,@com,@TVAv,@dfTVA
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @Valoare=0
set @Tva=0
set @Tva9=0
set @valoarev=0
set @ContF=@cont
set @gvaluta=@valuta
set @gcurs=@curs
set @gdf=@df
set @gds=@ds
set @glocm=@locm
set @gcom=@com
while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
begin
	if @ctip in (''RM'',''RP'',''RQ'',''RS'')
	begin		
		set @tipf=0x54
		set @cuTVA=(case when (@ctip=''RM'' and @dvi<>'''') or (@ctip=''RM'' and @dvi='''' or @ctip in (''RP'',''RS'')) and @dfTVA in (1) then 0 else 1 end)
		set @tva9=@tva9+(case when @cota in (9,11) then @semn*@cuTVA*@tvad else 0 end)
		set @tva=@tva+(case when @cota not in (9,11) then @semn*@cuTVA*@tvad else 0 end)
		set @disc=(case when abs(@disc+@cota*100/(@cota+100))<0.01 then convert(decimal(12,4),-@cota*100/(@cota+100)) 
			else convert(decimal(12,4),@disc) end)
		if @valuta='''' 
			set @valoare=@valoare+@semn*round(convert(decimal(17,5),@cant*round(@pval*(1+@disc/100),5)),@rotunjr_n)
		else
		begin
			if @dvi='''' set @valoare=@valoare+@semn*(case when @ctip=''RP'' then @pval else round(convert(decimal(17,5),@cant*round(convert(decimal(16,5),@pval*@curs*(1+@disc/100)),5)),@rotunjr_n) end)
			else set @valoare=@valoare+@semn*(case when @ctip=''RP'' then @pval when @ctip=''RM'' and @stoehr=1 and @df>=''06/01/2003'' then @pstoc*@cant else round(convert(decimal(17,5),@cant*round(convert(decimal(16,5),@pval*@curs),5)),@rotunjr_n) end)
			set @valoarev=@valoarev+@semn*round(convert(decimal(17,5),@cant*(case when @ctip=''RP'' then @pstoc else @pval end)*(1+(case when @ctip=''RS'' or @dvi='''' then @disc else 0 end)/100)),2)
			set @valoarev=@valoarev+@semn*@cuTVA*@TVAv
		end
	end
	else begin
		set @tipf=0x46
		set @cuTVA=(case when @ctip in (''AP'',''AS'') and @dfTVA in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or @ctip=''AS'') then 0 else 1 end)
		set @tva9=@tva9+(case when @cota in (9,11) then @semn*@cuTVA*@tvad else 0 end)
		set @tva=@tva+(case when @cota not in (9,11) then @semn*@cuTVA*@tvad else 0 end)
		set @valoare=@valoare+@semn*round(convert(decimal(17,5),@cant*@pvanz),@rotunj_n)
		if @valuta<>'''' begin
			set @valoarev=@valoarev+@semn*round(convert(decimal(17,5),@cant*(@pval*(1-@disc/100)+@LME/1000))+(case when @curs>0 then @cuTVA*@tvad/@curs else 0 end),2)
		end
	end
	if @semn=1 set @contF=@cont
	if @semn=1 set @gvaluta=@valuta
	if @semn=1 set @gcurs=@curs
	if @semn=1 set @gdf=@df
	if @semn=1 set @gds=@ds
	if @semn=1 set @glocm=@locm
	if @semn=1 set @gcom=@com

fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@tvad,@cant,@valuta,@curs,@pstoc,@pval,@pvanz,@cota,@disc,@cont,@dvi,@df,@ds,@LME,@locm,@com,@TVAv,@dfTVA
set @gfetch=@@fetch_status
end
update facturi set valoare=valoare+@valoare,tva_22=tva_22+@tva,tva_11=tva_11+@tva9,
	sold=sold+@valoare+@tva+@tva9,
	valuta='''',curs=0,
	cont_de_tert=@contF,loc_de_munca=@glocm,comanda=@gcom,
	data=(case when data>@gdf then @gdf else data end),data_scadentei=(case when data_scadentei>@gds then @gds else data_scadentei end)
where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura

update facturi set valoare_valuta=valoare_valuta+@valoarev,sold_valuta=sold_valuta+@valoarev,
	valuta=@gvaluta,curs=@gcurs 
from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura
	and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1 

set @gtert=@ctert
set @gsub=@csub
set @gfactura=@cfactura
set @gtip=@ctip
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docDxinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docDxinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docDxinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
/* triggere dare in folosinta - pt. cont intermediar*/
-------------	din tabela par (parametri trimis de Magic):
		declare @velpitar int
		set @velpitar=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''VELPITAR''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar, a.data, 
(case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end), a.cont_intermediar,
0, '''', 0, 0, (case when rtrim(max(factura))+rtrim(max(contract))<>'''' then rtrim(max(factura))+rtrim(max(contract)) else isnull((select rtrim(p.nume) from personal p where p.marca=max(a.gestiune_primitoare)),'''') end), 
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=(case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end) and cont_creditor=a.cont_intermediar 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
and left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' 
group by a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end), a.cont_intermediar,
a.loc_de_munca, a.comanda

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
@gcom char(40), @val float, @gfetch int
declare @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, 
@suma float, @locm char(9), @com char(40)

declare tmp cursor for
select a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end) as contd, a.cont_intermediar as contc, 1, cantitate*pret_de_stoc*(1-convert(decimal(12,3),procent_vama/100)), loc_de_munca, comanda from inserted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' 
union all
select a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end), a.cont_intermediar, 
-1, cantitate*pret_de_stoc*(1-convert(decimal(12,3),procent_vama/100)), loc_de_munca, comanda from deleted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' 
order by a.subunitate, tip, numar, data, contd, contc, loc_de_munca, comanda
open tmp
fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn, @suma, @locm, @com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val 
	 where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docDinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docDinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docDinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
/* triggere dare in folosinta */
-------------	din tabela par (parametri trimis de Magic):
		declare @cctva varchar(13), @ctvendf_a char(13), @ctvendf_l int, @velpitar int
		set @cctva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVA''),''''))
		set @ctvendf_a=isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CTVENDF''),'''')
		set @ctvendf_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CTVENDF''),0)
		set @velpitar=isnull((select top 1 val_logica from par where tip_parametru=''SP'' and parametru=''VELPITAR''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar, a.data, 
(case when left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' then a.cont_intermediar when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end), a.cont_de_stoc,
0, '''', 0, 0, (case when rtrim(max(factura))+rtrim(max(contract))<>'''' then rtrim(max(factura))+rtrim(max(contract)) else isnull((select rtrim(p.nume) from personal p where p.marca=max(a.gestiune_primitoare)), '''') end), 
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=(case when left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' then a.cont_intermediar when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end) and cont_creditor=a.cont_de_stoc 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, (case when left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' then a.cont_intermediar when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end), a.cont_de_stoc,
a.loc_de_munca, a.comanda

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_corespondent else a.cont_venituri end), (case when a.cont_corespondent like ''8%'' and @velpitar=0 then '''' else a.cont_intermediar end), 0, '''', 0, 0, (case when rtrim(max(factura))+rtrim(max(contract))<>'''' then rtrim(max(factura))+rtrim(max(contract)) else isnull((select rtrim(p.nume) from personal p where p.marca=max(a.gestiune_primitoare)),'''') end), 
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune 
and (a.cont_corespondent like ''8%'' or a.cont_venituri<>'''' and a.cont_intermediar<>'''')
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=(case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_corespondent else a.cont_venituri end) and cont_creditor=(case when a.cont_corespondent like ''8%'' and @velpitar=0 then '''' else a.cont_intermediar end) 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_corespondent else a.cont_venituri end), (case when a.cont_corespondent like ''8%'' and @velpitar=0 then '''' else a.cont_intermediar end), a.loc_de_munca, a.comanda

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, tip, numar, data, cont_factura, (case when @ctvendf_l=0 then a.cont_de_stoc else @ctvendf_a end), 0, '''', 0, 0, (case when rtrim(max(factura))+rtrim(max(contract))<>'''' then rtrim(max(factura))+rtrim(max(contract)) else isnull((select rtrim(p.nume) from personal p where p.marca=max(a.gestiune_primitoare)),'''') end), 
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a where tip=''DF'' and procent_vama>0 and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=a.cont_factura and cont_creditor=(case when @ctvendf_l=0 then a.cont_de_stoc else @ctvendf_a end) 
and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, (case when @ctvendf_l=0 then cont_de_stoc else @ctvendf_a end), a.cont_factura, a.loc_de_munca, a.comanda

insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, tip, numar, data, cont_factura, @cctva, 0, '''', 0, 0, (case when rtrim(max(factura))+rtrim(max(contract))<>'''' then rtrim(max(factura))+rtrim(max(contract)) else isnull((select rtrim(p.nume) from personal p where p.marca=max(a.gestiune_primitoare)),'''') end), 
max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a where tip=''DF'' and procent_vama>0 and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=a.cont_factura and cont_creditor=@cctva and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') group by a.subunitate, a.tip, a.numar, a.data, a.cont_factura, a.loc_de_munca, a.comanda

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
@gcom char(40), @val float, @gfetch int
declare @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, 
@suma float, @locm char(9), @com char(40)

declare tmp cursor for
select a.subunitate, a.tip, a.numar, a.data, (case when left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' then a.cont_intermediar when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end) as contd, a.cont_de_stoc as contc, 1, cantitate*pret_de_stoc*(1-(case when @ctvendf_l=0 then convert(decimal(12,3),procent_vama/100) else 0 end)), loc_de_munca, comanda from inserted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune 
union all
select a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_corespondent else a.cont_venituri end), (case when a.cont_corespondent like ''8%'' and @velpitar=0 then '''' else a.cont_intermediar end), 1, cantitate*pret_de_stoc*(1-convert(decimal(12,3),procent_vama/100)), loc_de_munca, comanda from inserted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and (a.cont_corespondent like ''8%'' or a.cont_venituri<>'''' and a.cont_intermediar<>'''')
union all
select subunitate, tip, numar, data, cont_factura, (case when @ctvendf_l=0 then cont_de_stoc else @ctvendf_a end), 1, cantitate*pret_de_stoc*procent_vama/100, loc_de_munca, comanda from inserted where tip=''DF'' and procent_vama>0 
union all
select subunitate, tip, numar, data, cont_factura, @cctva, 1, round(convert(decimal(17,5), cantitate*pret_de_stoc*procent_vama/100*cota_TVA/100),2), loc_de_munca, comanda from inserted where tip=''DF'' and procent_vama>0 
union all
select a.subunitate, a.tip, a.numar, a.data, (case when left(a.cont_de_stoc,3)=''371'' and rtrim(a.cont_intermediar)<>'''' then a.cont_intermediar when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_venituri else a.cont_corespondent end), a.cont_de_stoc, 
-1, cantitate*pret_de_stoc*(1-(case when @ctvendf_l=0 then convert(decimal(12,3),procent_vama/100) else 0 end)), loc_de_munca, comanda from deleted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune 
union all
select a.subunitate, a.tip, a.numar, a.data, (case when a.cont_corespondent like ''8%'' and @velpitar=0 then a.cont_corespondent else a.cont_venituri end), (case when a.cont_corespondent like ''8%'' and @velpitar=0 then '''' else a.cont_intermediar end), 
-1, cantitate*pret_de_stoc*(1-convert(decimal(12,3),procent_vama/100)), loc_de_munca, comanda from deleted a, gestiuni c where a.tip=''DF'' and a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and (a.cont_corespondent like ''8%'' or a.cont_venituri<>'''' and a.cont_intermediar<>'''')
union all
select subunitate, tip, numar, data, cont_factura, (case when @ctvendf_l=0 then cont_de_stoc else @ctvendf_a end), -1, cantitate*pret_de_stoc*procent_vama/100, loc_de_munca, comanda from deleted where tip=''DF'' and procent_vama>0 
union all
select subunitate, tip, numar, data, cont_factura, @cctva, -1, round(convert(decimal(17,5), cantitate*pret_de_stoc*procent_vama/100*cota_TVA/100),2), loc_de_munca, comanda from deleted where tip=''DF'' and procent_vama>0 
order by a.subunitate, tip, numar, data, contd, contc, loc_de_munca, comanda
open tmp
fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn, @suma, @locm, @com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val 
	 where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docdefinitiv]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docdefinitiv]'))
EXEC dbo.sp_executesql @statement = N'create trigger [dbo].[docdefinitiv] on [dbo].[pozdoc] for update, delete NOT FOR REPLICATION as

Declare @lDrepModif int
set @lDrepModif = (case when isnull((Select val_numerica from par where tip_parametru = ''MP'' and parametru = convert(char(8),abs(convert(int,host_id())))),0)<>0 then isnull((Select val_numerica from par where tip_parametru = ''MP'' and parametru = convert(char(8),abs(convert(int,host_id())))),0) when isnull((Select val_numerica from par where tip_parametru = ''MF'' and parametru = convert(char(8),abs(convert(int,host_id())))),0)<>0 then isnull((Select val_numerica from par where tip_parametru = ''MF'' and parametru = convert(char(8),abs(convert(int,host_id())))),0)
else isnull((Select max(convert(int, val_logica)) from par where tip_parametru=''DD'' and parametru = convert(char(8),abs(convert(int,host_id())))),0) end)

if exists (select 1 from deleted d 
left outer join inserted i on d.subunitate=i.subunitate and d.tip=i.tip and d.numar=i.numar and d.data=i.data where d.stare in (2,6,7) 
and not (d.stare=2 and isnull(i.stare, 0)=6) -- stornarea documentelor definitive
and not (d.stare=7 and isnull(i.stare, 0)=3) -- trecerea din stare validat inapoi in stare Operat
and (d.jurnal=''MPX'' and @lDrepModif<>4 or d.jurnal=''MFX'' and @lDrepModif<>2 or d.jurnal<>''MFX'' and d.jurnal<>''MPX'' and @lDrepModif<>1)) --and @lDrepModif = 0

begin
RAISERROR (''Violare integritate date. Incercare de modificare document definitiv (pozdoc)'', 16, 1)
rollback transaction
end
'
GO
/****** Object:  Trigger [docdec]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docdec]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docdec] on [dbo].[pozdoc] for insert, update, delete as
begin
insert deconturi
(Subunitate, Tip, Marca, Decont, Cont, Data, Data_scadentei, 
Valoare, Valuta, Curs, Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, 
Loc_de_munca, Comanda, Data_ultimei_decontari, Explicatii)
select a.subunitate, ''T'', a.gestiune_primitoare, a.tert, max(a.cont_factura), max(a.data), max(a.data), 
0, max(a.valuta), max(a.curs), 0, 0, 0, 0, 0, 
max(a.loc_de_munca), max(a.comanda), ''01/01/1901'', ''''
from inserted a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
where a.tip=''DF'' and c.sold_credit=9 and a.tert<>'''' and a.procent_vama<>0
and not exists (select 1 from deconturi d where d.subunitate=a.subunitate and d.tip=''T'' and d.marca=a.gestiune_primitoare and d.decont=a.tert)
group by a.subunitate, a.gestiune_primitoare, a.tert

declare @sub char(9), @marca char(6), @decont char(13), @valoare float, @lm char(9), @comanda char(40), @semn int, 
	@gsub char(9), @gmarca char(6), @gdecont char(13), @gvaloare float, @glm char(9), @gcomanda char(40), @nFetch int

declare tmpdocdec cursor for
select a.subunitate, a.gestiune_primitoare as marca, a.tert as decont, 
round(convert(decimal(15, 5), a.cantitate*a.pret_de_stoc*a.procent_vama/100*(1.00+a.cota_TVA/100.00)), 2) as valoare, 
a.loc_de_munca as loc_de_munca, a.comanda as comanda, 1 as semn
from inserted a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
where a.tip=''DF'' and c.sold_credit=9 and a.tert<>'''' and a.procent_vama<>0
union all 
select a.subunitate, a.gestiune_primitoare as marca, a.tert as decont, 
round(convert(decimal(15, 5), a.cantitate*a.pret_de_stoc*a.procent_vama/100*(1.00+a.cota_TVA/100.00)), 2) as valoare, 
a.loc_de_munca as loc_de_munca, a.comanda as comanda, -1 as semn
from deleted a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
where a.tip=''DF'' and c.sold_credit=9 and a.tert<>'''' and a.procent_vama<>0
order by 1, 2, 3

open tmpdocdec
fetch next from tmpdocdec into @sub, @marca, @decont, @valoare, @lm, @comanda, @semn
select @nFetch=@@fetch_status, @gsub=@sub, @gmarca=@marca, @gdecont=@decont
while @nFetch=0
begin
	select @gvaloare=0, @glm='''', @gcomanda=''''
	while @nFetch=0 and @gsub=@sub and @gmarca=@marca and @gdecont=@decont
	begin
		select @gvaloare=@gvaloare+@semn*@valoare, 
			@glm=(case when @semn=1 and @lm<>'''' then @lm else @glm end), 
			@gcomanda=(case when @semn=1 and @comanda<>'''' then @comanda else @gcomanda end)
		fetch next from tmpdocdec into @sub, @marca, @decont, @valoare, @lm, @comanda, @semn
		set @nFetch=@@fetch_status
	end
	
	update deconturi
	set valoare=valoare+@gvaloare, sold=sold+@gvaloare, 
		loc_de_munca=(case when @glm<>'''' then @glm else loc_de_munca end), comanda=(case when @gcomanda<>'''' then @gcomanda else comanda end)
	where subunitate=@gsub and tip=''T'' and marca=@gmarca and decont=@gdecont
end
close tmpdocdec
deallocate tmpdocdec
end
'
GO
/****** Object:  Trigger [doccontr]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[doccontr]'))
EXEC dbo.sp_executesql @statement = N'--***
/*Pentru completare cant. realizata*/
create trigger [dbo].[doccontr] on [dbo].[pozdoc] for update,insert,delete NOT FOR REPLICATION as
begin
-------------	din tabela par (parametri trimis de Magic):
declare @rezstoc int, @multicdbk int, @pozsurse int
set @rezstoc=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''REZSTOC''),0)
set @multicdbk=isnull((select top 1 val_logica from par where tip_parametru=''UC'' and parametru=''MULTICDBK''),0)
set @pozsurse=isnull((select top 1 val_logica from par where tip_parametru=''UC'' and parametru=''POZSURSE''),0)
-------------
declare @realizat float
declare @csub char(9),@ccod char(20), @barcod char(8), @ctip char(2),@ccontr char(20),@ctert char(13),@cgest char(9),@semn int,@cant float,@ctipcontr char(1),@ccodi char(13),@clocatie char(20),@pret float
declare @gsub char(9),@gcod char(20),@gbarcod char(8), @gtip char(2),@gcontr char(20),@gtert char(13),@ggest char(9),@gcodi char(13), @glocatie char(20),@gid int,@gpret float,@gfetch int
declare @cGestPrim char(9), @gGestPrim char(9)

declare tmpCo cursor for
select subunitate,cod,barcod, tip,contract,tert,1,cantitate,(case when left(tip,1)=''R'' then ''F'' else ''B'' end),
(case when @rezstoc=1 then gestiune else '''' end) as gest,(case when @rezstoc=1 and left(tip,1)=''A'' then cod_intrare else '''' end) as codi,locatie,
(case when left(tip,1)=''R'' or valuta<>'''' then pret_valuta else pret_vanzare end)
from inserted where tip in (''AC'',''AP'',''AS'',''RM'',''RS'') and contract<>'''' 
union all
select subunitate,cod,barcod, tip,contract,tert,-1,cantitate,(case when left(tip,1)=''R'' then ''F'' else ''B'' end),
(case when @rezstoc=1 then gestiune else '''' end),(case when @rezstoc=1 and left(tip,1)=''A'' then cod_intrare else '''' end),locatie,
(case when left(tip,1)=''R'' or valuta<>'''' then pret_valuta else pret_vanzare end)
from deleted where tip in (''AC'',''AP'',''AS'',''RM'',''RS'') and contract<>''''
order by subunitate,tip,contract/*,tert*/,cod,gest,locatie

open tmpCo
fetch next from tmpCo into @csub,@ccod,@barcod,@ctip,@ccontr,@ctert,@semn,@cant,@ctipcontr,@cgest,@ccodi,@clocatie,@pret
set @gsub=@csub
set @gtip=@ctip
set @gcontr=@ccontr
--set @gtert=@ctert
set @gcod=@ccod
set @gbarcod=(case when @pozsurse=1 and @ctipcontr=''B'' then @barcod else '''' end)
set @ggest=@cgest
set @gcodi=@ccodi
set @gpret=(case when @multicdbk=1 and @ctipcontr=''B'' then @pret else 0 end)
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @realizat=0
	set @gid=0
	set @glocatie=@clocatie
	while @gsub=@csub and @gTip=@cTip and @gcontr=@ccontr --and @gtert=@ctert 
		and @gcod=@ccod and (@rezstoc=0 or @ggest=@cgest and @gcodi=@ccodi) 
		and @gpret=(case when @multicdbk=1 and @ctipcontr=''B'' then @pret else 0 end)
		and @gbarcod=(case when @pozsurse=1 and @ctipcontr=''B'' then @barcod else '''' end)
		and @gfetch=0
	begin
		set @realizat=@realizat+@semn*@cant 
		if @semn=1 set @glocatie=@clocatie
		fetch next from tmpCo into @csub,@ccod,@barcod,@ctip,@ccontr,@ctert,@semn,@cant,@ctipcontr,@cgest,@ccodi,@clocatie,@pret
		set @gfetch=@@fetch_status
	end
	update pozcon set cant_realizata=cant_realizata+@realizat,@gid=1
		where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr --and tert=@gtert 
		and cod=@gcod 
		and (@rezstoc=0 or @rezstoc=1 and mod_de_plata=@ggest 
			and (left(@gtip,1)=''A'' or factura=@glocatie) and (left(@gtip,1)=''R'' or valuta=@gcodi) 
			and zi_scadenta_din_luna=0 and (left(@gtip,1)=''R'' or contract<>@glocatie))
		and ((@ctipcontr = ''B'' and tip = ''BK'') or (@ctipcontr = ''F'' and tip = ''FC'') or (@ctipcontr = ''B'' and tip = ''BP''))
		and (@multicdbk=0 or @multicdbk=1 and (@ctipcontr<>''B'' or abs(pret-@gpret)<=0.001))
		and (@pozsurse=0 or @pozsurse=1 and (@ctipcontr<>''B'' or mod_de_plata=@gbarcod))

	/*cu rezervari de stocuri*/
	update pozcon set cant_realizata=cant_realizata+@realizat
		where @rezstoc=1 and @gid=0 and left(@gtip,1)=''A'' and subunitate=@gsub and tip=''BF'' and
		contract=@gcontr and /*tert=@gtert and */cod=@gcod and zi_scadenta_din_luna>0

	/* Modificare stare contract*/
--	update con set stare=''6'' 
	--	where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr /*and tert=@gtert*/
		--and tip<>''BF''

	set @gsub=@csub
	set @gtip=@ctip
	set @gcontr=@ccontr
	--set @gtert=@ctert
	set @gcod=@ccod
	set @gbarcod=(case when @pozsurse=1 and @ctipcontr=''B'' then @barcod else '''' end)
	set @ggest=@cgest
	set @gcodi=@ccodi
	set @gpret=(case when @multicdbk=1 and @ctipcontr=''B'' then @pret else 0 end)
end

close tmpCo
deallocate tmpCo

-- realizat pe TE

declare tmpCo cursor for
select subunitate, (case when tip=''AE'' then '''' when contract<>'''' then contract else gestiune_primitoare end) as gestiune_primitoare, 
cod, (case when tip=''AE'' then grupa else factura end),  1, cantitate, pret_cu_amanuntul
from inserted where (tip = ''TE'' and factura <> '''' or tip=''AE'' and grupa<>'''')
union all
select subunitate, (case when tip=''AE'' then '''' when contract<>'''' then contract else gestiune_primitoare end) as gestiune_primitoare, 
cod, (case when tip=''AE'' then grupa else factura end), -1, cantitate, pret_cu_amanuntul
from deleted where (tip = ''TE'' and factura <> '''' or tip=''AE'' and grupa<>'''')

open tmpCo
fetch next from tmpCo into @csub, @cGestPrim, @ccod, @ccontr, @semn, @cant, @pret
set @gsub=@csub
set @gGestPrim=@cGestPrim
set @gcod=@ccod
set @gcontr=@ccontr
set @gpret=(case when @multicdbk=1 then @pret else 0 end)
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @realizat=0
	while @gsub=@csub and @gGestPrim=@cGestPrim and @gcontr=@ccontr and @gcod=@ccod 
		and @gpret=(case when @multicdbk=1 then @pret else 0 end) and @gfetch=0
	begin
		set @realizat=@realizat+@semn*@cant 
		fetch next from tmpCo into @csub, @cGestPrim, @ccod, @ccontr, @semn, @cant, @pret
		set @gfetch=@@fetch_status
	end
	update pozcon 
	set pret_promotional=p.pret_promotional+@realizat
	from pozcon p 
	left outer join gestiuni g on p.punct_livrare<>'''' and p.subunitate=g.subunitate and p.punct_livrare=g.cod_gestiune
	where p.subunitate=@gsub and p.tip=''BK'' and p.contract=@gcontr and p.cod=@gcod
	and (@gGestPrim='''' or p.punct_livrare = @gGestPrim)
	and (@multicdbk=0 or abs(round(convert(decimal(17, 5), pret*(1.00+(case when isnull(g.tip_gestiune, '''') not in (''A'', ''V'') then p.cota_TVA else 0 end)/100.00)), 5)-@gpret)<=0.001)

	set @gsub=@csub
	set @gGestPrim=@cGestPrim
	set @gcod=@ccod
	set @gcontr=@ccontr
	set @gpret=(case when @multicdbk=1 then @pret else 0 end)
end

close tmpCo
deallocate tmpCo
end
'
GO
/****** Object:  Trigger [docBxinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docBxinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docBxinc] on [dbo].[pozdoc] for update,insert,delete as
begin 
--ad. primitor
-------------	din tabela par (parametri trimis de Magic):
		declare @adtav_l int, @cont348_l int, @modatim int, @rotunjtnx int, @timbrult2 int, @adtav_n int, @adtava int, @transilva int
		set @adtav_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @cont348_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONT348''),0)
		set @modatim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MODATIM''),0)
		set @rotunjtnx=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJTNX''),0)
		set @timbrult2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULT2''),0)
		set @adtav_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @adtava=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAVA''),0)
		set @transilva=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TRANSILVA''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar,data,
(case when a.tip=''TE'' and not(@modatim=1 and c.tip_gestiune in (''A'',''V'') and a.cont_corespondent like ''35%'') then a.cont_corespondent else a.cont_de_stoc end),
(case when tip=''TE'' then cont_venituri else gestiune_primitoare end),
0,'''',0,0,max(''Ad. prim. ''+tip+'' ''+rtrim(numar)+'' ''    +rtrim(gestiune)),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a,gestiuni c 
where a.subunitate=c.subunitate and (case when a.tip=''TE'' then a.gestiune_primitoare else a.gestiune end)=c.cod_gestiune 
and not((a.tip=''AC'' or a.tip=''AP'' and cont_de_stoc like ''357%'') and @modatim=1) and a.tip in (''RM'',''AP'',''AC'',''TE'',''AI'') 
and (a.tip=''TE'' and (a.cont_corespondent like ''371%'' or /*@modatim=1 and*/ a.cont_corespondent like ''35%'') or a.tip<>''TE'' and left(a.cont_de_stoc,2) in (''37'',''35'')) 
and not (a.tip=''AI'' and a.cont_de_stoc like ''354%'') 
and (a.tip in (''RM'',''AI'') and c.tip_gestiune in (''A'',''V'') 
	or a.tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or a.tip=''AC'') or @adtava=1) and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 and (@adtav_n=0 or a.tip=''AC'') then ''C'' else ''!'' end),(case when @adtava=1 then ''A'' else ''!'' end))) 
	or a.tip=''TE'' and c.tip_gestiune in (''A'',''V'')) and not (a.tip=''AP'' and @transilva=1 and a.tert in (select tert from terti where tert_extern=1)) 
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data and cont_debitor=(case when a.tip=''TE'' and not(@modatim=1 and c.tip_gestiune in (''A'',''V'') and a.cont_corespondent like ''35%'') then a.cont_corespondent else a.cont_de_stoc end) and cont_creditor=(case when a.tip=''TE'' then a.cont_venituri else a.gestiune_primitoare end) and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data,(case when a.tip=''TE'' and not(@modatim=1 and c.tip_gestiune in (''A'',''V'') and a.cont_corespondent like ''35%'') then a.cont_corespondent else a.cont_de_stoc end),(case when tip=''TE'' then cont_venituri else gestiune_primitoare end),a.loc_de_munca,a.comanda

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40),@val float,@gfetch int,@sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int,@suma float,@locm char(9),@com char(40)

declare tmp cursor for 
select subunitate,tip,numar,data,
(case when tip=''TE'' and not(@modatim=1 and subunitate+gestiune_primitoare in (select subunitate+cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) and cont_corespondent like ''35%'') then cont_corespondent else cont_de_stoc end) as contd,
(case when tip=''TE'' then cont_venituri else gestiune_primitoare end) as contc,
1,(case when tip in (''AP'',''AC'') then round(convert(decimal(17,5),cantitate*(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)),2)+(case when tip=''AP'' then round(convert(decimal(17,5),tva_deductibil),2) else 0 end)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)-round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5),(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)*cota_tva/(100+(case when tip=''AC'' then cota_tva else 0 end))),@rotunjtnx)),2) when (tip=''TE'' and tert like ''348%'' and valuta<>'''') or (@cont348_l=1 and tip=''AI'' and cont_de_stoc like ''371%'') then cantitate*(pret_cu_amanuntul-round(convert(decimal(17,5),pret_cu_amanuntul*TVA_neexigibil /(100+TVA_neexigibil)),@rotunjtnx))-(case when tip=''TE'' and valuta<>'''' and pret_valuta>0 then cantitate*pret_valuta*curs else cantitate*pret_amanunt_predator end) else round(cantitate*pret_cu_amanuntul,2)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)-(case when (tip = ''RM'' and (@timbrult2=1 and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A''))) then round(cantitate*accize_cumparare,2) else 0 end)-round(convert(decimal(15,3),cantitate*round(convert(decimal(17,5),pret_cu_amanuntul*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),2) end)-(case when tip=''TE'' and @timbrult2=1 then cantitate*accize_cumparare else 0 end)-(case when tip in (''AP'',''AC'') and @adtava=1 and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A'') then round(convert(decimal(17,5),cantitate*pret_amanunt_predator),2)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)-round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5),pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),2) else 0 end),loc_de_munca,comanda 
from inserted 
where not((tip=''AC'' or tip=''AP'' and cont_de_stoc like ''357%'') and @modatim=1) 
and tip in (''RM'',''AP'',''AC'',''TE'',''AI'') and (tip=''TE'' and (cont_corespondent like ''371%'' or /*@modatim=1 and*/ cont_corespondent like ''35%'') or tip<>''TE'' and left(cont_de_stoc,2) in (''37'',''35'')) 
and not (tip=''AI'' and cont_de_stoc like ''354%'') and (tip in (''RM'',''AI'') and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) 
	or tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end),(case when @adtava=1 then ''A'' else ''!'' end))) 
	or tip=''TE'' and gestiune_primitoare in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V''))) and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
union all
select subunitate,tip,numar,data,
(case when tip=''TE'' and not(@modatim=1 and subunitate+gestiune_primitoare in (select subunitate+cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) and cont_corespondent like ''35%'') then cont_corespondent else cont_de_stoc end) as contd,
(case when tip=''TE'' then cont_venituri else gestiune_primitoare end) as contc,
-1,(case when tip in (''AP'',''AC'') then round(convert(decimal(17,5),cantitate*(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)),2)+(case when tip=''AP'' then round(convert(decimal(17,5),tva_deductibil),2) else 0 end)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)-round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5),(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)*cota_tva/(100+(case when tip=''AC'' then cota_tva else 0 end))),@rotunjtnx)),2) when (tip=''TE'' and tert like ''348%'' and valuta<>'''') or (@cont348_l=1 and tip=''AI'' and cont_de_stoc like ''371%'') then cantitate*(pret_cu_amanuntul-round(convert(decimal(17,5),pret_cu_amanuntul*TVA_neexigibil /(100+TVA_neexigibil)),@rotunjtnx))-(case when tip=''TE'' and valuta<>'''' and pret_valuta>0 then cantitate*pret_valuta*curs else cantitate*pret_amanunt_predator end) else round(cantitate*pret_cu_amanuntul,2)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)-(case when (tip = ''RM'' and (@timbrult2=1 and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A''))) then round(cantitate*accize_cumparare,2) else 0 end)-round(convert(decimal(15,3),cantitate*round(convert(decimal(17,5),pret_cu_amanuntul*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),2) end)-(case when tip=''TE'' and @timbrult2=1 then cantitate*accize_cumparare else 0 end)-(case when tip in (''AP'',''AC'') and @adtava=1 and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A'') then round(convert(decimal(17,5),cantitate*pret_amanunt_predator),2)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)-round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5),pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),2) else 0 end),loc_de_munca,comanda 
from deleted 
where not((tip=''AC'' or tip=''AP'' and cont_de_stoc like ''357%'') and @modatim=1) 
and tip in (''RM'',''AP'',''AC'',''TE'',''AI'') and (tip=''TE'' and (cont_corespondent like ''371%'' or /*@modatim=1 and*/ cont_corespondent like ''35%'') or tip<>''TE'' and left(cont_de_stoc,2) in (''37'',''35'')) 
and not (tip=''AI'' and cont_de_stoc like ''354%'') and (tip in (''RM'',''AI'') and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) 
	or tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end),(case when @adtava=1 then ''A'' else ''!'' end))) 
	or tip=''TE'' and gestiune_primitoare in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V''))) and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
order by subunitate,tip,numar,data,contd,contc,loc_de_munca,comanda
open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@locm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @val=0
while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0 
begin
set @val=@val+@suma*@semn
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@locm,@com
set @gfetch=@@fetch_status
end 
update pozincon set suma=suma+@val where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom 
delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and suma=0 and suma_valuta=0
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [docBinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docBinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docBinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-- TVA neex primitor
-------------	din tabela par (parametri trimis de Magic):
		declare @adtav_l int, @rotunjtnx int, @modatim int, @adtav_n int, @adtava int, @transilva int
		set @adtav_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @rotunjtnx=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJTNX''),0)
		set @modatim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MODATIM''),0)
		set @adtav_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @adtava=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAVA''),0)
		set @transilva=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TRANSILVA''),0)
-------------
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate,tip,numar,data, (case when tip=''TE'' then cont_corespondent else cont_de_stoc end), 
(case when tip in (''TE'',''AI'') then cont_factura when tip=''RM'' then cont_intermediar else rtrim(left(numar_DVI,13)) end),
0,'''',0,0,max(''TVA neex. prim. ''+tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_de_munca,comanda,max(jurnal)
from inserted a 
where not(a.tip in (''AP'',''AC'') and @modatim=1) and a.tip in (''RM'',''AP'',''AC'',''TE'',''AI'') 
--and (a.tip=''TE'' and (a.cont_corespondent like ''371%'' or a.cont_corespondent like ''357%'') or a.tip<>''TE'' and left(a.cont_de_stoc,2) in (''37'',''35''))
-- daca se vor opera TE cu cont primitor 354 sa se poata genera, totusi, adaos la primitor
and (a.tip=''TE'' and left(a.cont_corespondent,2) in (''37'',''35'') or a.tip<>''TE'' and left(a.cont_de_stoc,2) in (''37'',''35''))
and not (a.tip=''AI'' and a.cont_de_stoc like ''354%'') 
and (a.tip in (''RM'',''AI'') and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) 
	or a.tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or a.tip=''AC'') or @adtava=1) and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 and (@adtav_n=0 or a.tip=''AC'') then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	or a.tip=''TE'' and a.gestiune_primitoare in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V''))) 
and not (a.tip=''AP'' and @transilva=1 and a.tert in (select tert from terti where tert_extern=1)) and 
not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
and data=a.data and cont_debitor=(case when a.tip=''TE'' then a.cont_corespondent else a.cont_de_stoc end) 
and cont_creditor=(case when a.tip in (''TE'',''AI'') then a.cont_factura when a.tip=''RM'' then a.cont_intermediar 
else rtrim(left(a.numar_DVI,13)) end)and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate,a.tip,a.numar,a.data, (case when tip=''TE'' then cont_corespondent else cont_de_stoc end), 
(case when tip in (''TE'',''AI'') then cont_factura when tip=''RM'' then cont_intermediar else rtrim(left(numar_DVI,13)) end), a.loc_de_munca,  a.comanda

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gctd char(13),@gctc char(13),@glm char(9), @gcom char(40),@val float,@gfetch int, @sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int, @suma float, @locm char(9),@com char(40)

declare tmp cursor for 
select subunitate,tip,numar,data,(case when tip=''TE'' then cont_corespondent else cont_de_stoc end) as contd,(case when tip in (''TE'',''AI'') then cont_factura when tip=''RM'' then cont_intermediar else rtrim(left(numar_DVI,13)) end) as contc,1, 
(case when tip=''AP'' then round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5), pret_vanzare*cota_TVA/100), @rotunjtnx)), 2) 
	else round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5), pret_cu_amanuntul*(case when tip=''AC'' then cota_TVA else TVA_neexigibil end)/(100+(case when tip=''AC'' then cota_TVA else TVA_neexigibil end))), @rotunjtnx)), 2) end) 
- (case when tip in (''AP'',''AC'') and @adtava=1 and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A'') then round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)), 2) else 0 end), 
loc_de_munca,comanda 
from inserted 
where not(tip in (''AP'',''AC'') and @modatim=1) and tip in (''RM'',''AP'',''AC'',''TE'',''AI'') 
--and (tip=''TE'' and (cont_corespondent like ''371%'' or cont_corespondent like ''357%'') or tip<>''TE'' and left(cont_de_stoc,2) in (''37'',''35'')) 
and (tip=''TE'' and left(cont_corespondent,2) in (''37'',''35'') or tip<>''TE'' and left(cont_de_stoc,2) in (''37'',''35''))
and not (tip=''AI'' and cont_de_stoc like ''354%'') 
and (tip in (''RM'',''AI'') and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) 
	or tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	or tip=''TE'' and gestiune_primitoare in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V''))) and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
union all
select subunitate,tip,numar,data,(case when tip=''TE'' then cont_corespondent else cont_de_stoc end),(case when tip in (''TE'',''AI'') then cont_factura when tip=''RM'' then cont_intermediar else rtrim(left(numar_DVI,13)) end), -1, 
(case when tip=''AP'' then round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5), pret_vanzare*cota_TVA/100), @rotunjtnx)), 2) 
	else round(convert(decimal(17,5),cantitate*round(convert(decimal(17,5), pret_cu_amanuntul*(case when tip=''AC'' then cota_TVA else TVA_neexigibil end)/(100+(case when tip=''AC'' then cota_TVA else TVA_neexigibil end))), @rotunjtnx)), 2) end) 
- (case when tip in (''AP'',''AC'') and @adtava=1 and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''A'') then round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)), 2) else 0 end), 
loc_de_munca,comanda 
from deleted 
where not(tip in (''AP'',''AC'') and @modatim=1) and tip in (''RM'',''AP'',''AC'',''TE'',''AI'') 
--and (tip=''TE'' and (cont_corespondent like ''371%'' or cont_corespondent like ''357%'') or tip<>''TE'' and left(cont_de_stoc,2) in (''37'',''35'')) 
and (tip=''TE'' and left(cont_corespondent,2) in (''37'',''35'') or tip<>''TE'' and left(cont_de_stoc,2) in (''37'',''35''))
and not (tip=''AI'' and cont_de_stoc like ''354%'') 
and (tip in (''RM'',''AI'') and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V'')) 
	or tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	or tip=''TE'' and gestiune_primitoare in (select cod_gestiune from gestiuni where tip_gestiune in (''A'',''V''))) and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
order by subunitate,tip,numar,data,contd,contc,loc_de_munca,comanda

open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@locm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @val=0
while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd and @gctc=@contc 
and @glm=@locm and @gcom=@com and @gfetch=0 
begin
 set @val=@val+@suma*@semn
  fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@locm,@com
	set @gfetch=@@fetch_status
end 
update pozincon set suma=suma+@val 
 where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docAxinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docAxinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docAxinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-- Adaos predator 
-------------	din tabela par (parametri trimis de Magic):
		declare @adtav_l int, @rotunjtnx int, @modatim int, @faradesc int, @dafora int, @timbrult2 int, @adtav_n int, @adtava int, 
				@transilva int, @invaddesc int
		set @adtav_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @rotunjtnx=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJTNX''),0)
		set @modatim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MODATIM''),0)
		set @faradesc=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''FARADESC''),0)
		set @dafora=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DAFORA''),0)
		set @timbrult2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TIMBRULT2''),0)
		set @adtav_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @adtava=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAVA''),0)
		set @transilva=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TRANSILVA''),0)
		set @invaddesc=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''INVADDESC''),0)
-------------
  insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, tip, numar, data, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip in (''CM'',''TE'') then tert else gestiune_primitoare end), 
(case when tip in (''CM'',''TE'') and @invaddesc=0 then tert when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then gestiune_primitoare else cont_de_stoc end),
0, '''', 0, 0, left(max(''Ad. pred. ''+tip+'' ''+rtrim(numar)+
'' ''+rtrim(gestiune)),50), max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
from inserted a where a.tip in (''CM'',''AP'',''AC'',''TE'',''AE'') and not(a.tip=''AC'' and @modatim=1) and left(a.cont_de_stoc,2) in (''37'',''35'') and  not (a.tip in (''AP'',''AC'') and left(a.cont_de_stoc,3)=''354'')
and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when a.tip<>''TE'' and @faradesc=1 then ''!'' else ''A'' end),''V'',(case when @adtav_l=1 and a.tip in (''AP'',''AC'') and (@adtav_n=0 or a.tip=''AC'') then ''C'' else ''!'' end))) 
and not (a.tip=''AP'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) and not (a.tip=''AP'' and @transilva=1 and a.tert in (select tert from terti where tert_extern=1))
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar and data=a.data 
	and cont_debitor=(case when a.tip in (''CM'',''TE'') and @invaddesc=0 or a.tip=''AE'' and @dafora=1 and a.cont_corespondent like ''48%'' then a.cont_de_stoc when a.tip in (''CM'',''TE'') then a.tert else a.gestiune_primitoare end) 
	and cont_creditor=(case when a.tip in (''CM'',''TE'') and @invaddesc=0 then a.tert when a.tip=''AE'' and @dafora=1 and a.cont_corespondent like ''48%'' then a.gestiune_primitoare else a.cont_de_stoc end) 
	and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
group by a.subunitate, a.tip, a.numar, a.data, (case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip in (''CM'',''TE'') then tert else gestiune_primitoare end), (case when tip in (''CM'',''TE'') and @invaddesc=0 then tert when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then gestiune_primitoare else cont_de_stoc end), a.loc_de_munca, a.comanda

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
     @gcom char(40), @val float, @gfetch int
declare @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, 
     @suma float, @locm char(9), @com char(40)

declare tmp cursor for
select subunitate, tip, numar, data, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip in (''CM'',''TE'') then tert else gestiune_primitoare end) as contd, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 then tert when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then gestiune_primitoare else cont_de_stoc end) as contc, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then -1 else 1 end) as semn, 
(case when tip in (''AP'', ''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	then round(convert(decimal(17,5), cantitate*(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)), 2) - round(convert(decimal(17,5), cantitate*pret_de_stoc), 2) - round(convert(decimal(17,5), (case when tip=''AC'' then cantitate*round(convert(decimal(17,5),pret_cu_amanuntul*cota_tva/(100+cota_tva)),@rotunjtnx) else 0 end)), 2) 
	else round(convert(decimal(17,5), cantitate*pret_amanunt_predator), 2) - round(convert(decimal(17,5), cantitate*pret_de_stoc), 2) - round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)), 2) - round(convert(decimal(17,5), (case when tip=''TE'' then @timbrult2*cantitate*accize_cumparare else 0 end)), 2) end), 
loc_de_munca, comanda 
from inserted 
where tip in (''CM'',''AP'',''AC'',''TE'',''AE'') and not (tip=''AC'' and @modatim=1) and left(cont_de_stoc,2) in (''37'',''35'') and not (tip in (''AP'',''AC'') and left(cont_de_stoc,3)=''354'') and not (tip=''AP'' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when tip<>''TE'' and @faradesc=1 then ''!'' else ''A'' end),''V'',(case when @adtav_l=1 and tip in (''AP'',''AC'') and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end))) 
and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
union all
select subunitate, tip, numar, data, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip in (''CM'',''TE'') then tert else gestiune_primitoare end), 
(case when tip in (''CM'',''TE'') and @invaddesc=0 then tert when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then gestiune_primitoare else cont_de_stoc end), 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then 1 else -1 end), 
(case when tip in (''AP'', ''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	then round(convert(decimal(17,5), cantitate*(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)), 2) + round(convert(decimal(17,5), (case when tip=''AP'' then tva_deductibil else 0 end)), 2) - round(convert(decimal(17,5), cantitate*pret_de_stoc), 2) - round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5),(case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)*cota_tva/(100+(case when tip=''AC'' then cota_tva else 0 end))),@rotunjtnx)), 2) 
	else round(convert(decimal(17,5), cantitate*pret_amanunt_predator), 2) - round(convert(decimal(17,5), cantitate*pret_de_stoc), 2) - round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)), 2) - round(convert(decimal(17,5), (case when tip=''TE'' then @timbrult2*cantitate*accize_cumparare else 0 end)), 2) end), 
loc_de_munca, comanda 
from deleted 
where not(tip=''AC'' and @modatim=1) and tip in (''CM'',''AP'',''AC'',''TE'',''AE'') and left(cont_de_stoc,2) in (''37'',''35'') and not(tip in (''AP'',''AC'') and left(cont_de_stoc,3)=''354'') and not (tip=''AP'' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when tip<>''TE'' and @faradesc=1 then ''!'' else ''A'' end),''V'',(case when @adtav_l=1 and tip in (''AP'',''AC'') and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end))) 
and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
order by subunitate, tip, numar, data, contd, contc, loc_de_munca, comanda

open tmp
fetch next from tmp into @sub,@tip,@numar,@data, @contd,@contc,@semn,@suma, @locm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val 
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docantet]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docantet]'))
EXEC dbo.sp_executesql @statement = N'--***
/*Pentru creat antet document*/
create trigger [dbo].[docantet] on [dbo].[pozdoc] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	--HE, [IF (FK,FL,2)],[IF (FO,FP,2)],[GB OR ''TRUE''LOG],FM,HH
	declare @datapcons int, @rotunj_n int, @rotunjr_n int, @dve int, @accimp int , @comppret int, @urmc2 int 
	set @datapcons=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DATAPCONS''),0)
	set @rotunj_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJ'' and val_logica=1),2)
	set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJR'' and val_logica=1),2)
	--set @dve=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DVE''),0)	/**	anulat in Magic (cu ''OR True'')*/
	set @accimp=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ACCIMP''),0)
	set @comppret=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''COMPPRET''),0)
	set @urmc2=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''URMCANT2''),0)
-------------
insert into doc 
	(Subunitate, Tip, Numar, Cod_gestiune, Data, Cod_tert, Factura, Contractul, Loc_munca, Comanda, Gestiune_primitoare, Valuta, Curs, Valoare, Tva_11, Tva_22, Valoare_valuta, Cota_TVA, Discount_p, Discount_suma, Pro_forma, Tip_miscare, Numar_DVI, Cont_factura, Data_facturii, Data_scadentei, Jurnal, Numar_pozitii, Stare)
	select subunitate,tip,numar,max(gestiune),max(data),max(tert),max(factura),max(contract),max(loc_de_munca),max(comanda),
	max(case when tip in (''AP'',''AS'') then rtrim(substring(numar_dvi,14,5)) when tip=''AE'' then grupa else gestiune_primitoare end), max(valuta),max(curs),0,0,0,0,max(case when tip in (''RM'',''RS'') and numar_DVI<>'''' then 0 else Procent_vama end), max(discount), max(accize_cumparare),0,min(tip_miscare), 
	max(case when --@dve=1 and 
		tip in (''AP'',''AS'') then barcod when tip in (''RM'',''RS'') then rtrim(left(numar_dvi,13)) else '''' end),
	max(cont_factura),max(data_facturii),max(data_scadentei),max(jurnal),0,max(stare)
	from inserted where numar not in
	(select numar from doc where subunitate=inserted.subunitate and 
	((tip=''CM'' and @datapcons=1 and data between dateadd(day, 1-day(inserted.data), inserted.data) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(inserted.data), inserted.data)))) 
	or data=inserted.data) and tip=inserted.tip) 
	group by subunitate, tip, numar, (case when tip=''CM'' and @datapcons=1 then getdate() else data end)

/*Pentru calculul valorilor*/
declare @Valoare float, @Tva float, @Tva9 float, @valoarev float, @numar_poz int, @gfact char(20), @gdf datetime, @gds datetime
declare @csub char(9),@ctip char(2),@cnumar char(8),@cdata datetime,@ctert char(13),@semn int,@cant float,@valuta char(3),@curs float, 
	@pstoc float,@pval float,@pvanz float,@cota float,@tvad float,@numar_dvi char (8), @fact char(20), @df datetime, 
	@ds datetime, @disc float, @LME float, @ct4428 char(13), @gct4428 char(13), @gprim char(13), @ggprim char(13), @stare int, @clm char(9), @ccom char(40), @ccont_fact char(13), @ctip_tva smallint, @cgest char(9) 
declare @gsub char(9),@gtip char(2),@gnumar char(8),@gdata datetime,@gtert char(13),@gvaluta char(3),@gcurs float,@gfetch int, @gstare int, @gRetur int, @glm char(9), @gcom char(40), @gcont_fact char(13), @gtip_tva smallint, @ggest char(9)

declare tmp cursor for
select subunitate,tip,numar,data,tert,1,cantitate,valuta,curs,pret_de_stoc,pret_valuta,pret_vanzare,cota_tva,tva_deductibil, 
numar_dvi,factura,data_facturii, data_scadentei, discount, suprataxe_vama, grupa, cont_venituri, stare, loc_de_munca, comanda, cont_factura, procent_vama, gestiune 
from inserted union all
select subunitate,tip,numar,data,tert,-1,cantitate,valuta,curs,pret_de_stoc,pret_valuta,pret_vanzare,cota_tva,tva_deductibil, 
numar_dvi,factura,data_facturii, data_scadentei, discount, suprataxe_vama, grupa, cont_venituri, stare, loc_de_munca, comanda, cont_factura, procent_vama, gestiune
from deleted 
order by subunitate,tip,numar,data

open tmp
fetch next from tmp into @csub,@ctip,@cnumar,@cdata,@ctert,@semn,@cant,@valuta,@curs,
	@pstoc,@pval,@pvanz,@cota,@tvad,@numar_dvi,@fact,@df,@ds, @disc, @LME, @ct4428, @gprim, @stare, @clm, @ccom, @ccont_fact,@ctip_tva, @cgest 
set @gsub=@csub
set @gtip=@ctip
set @gnumar=@cnumar
set @gdata=@cdata
set @gtert=@ctert
set @glm=@clm 
set @gcom=@ccom
set @gcont_fact=@ccont_fact
set @gtip_tva=@ctip_tva
set @ggest=@cgest
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Tva=0
	set @Tva9=0
	set @valoarev=0
	set @numar_poz=0
	set @gvaluta=@valuta
	set @gcurs=@curs
	set @gfact=@fact
	set @gdf=@df
	set @gds=@ds
	set @gct4428=@ct4428
	set @ggprim=@gprim
	set @gstare=0
	set @gRetur=0
	while @gsub=@csub and @gTip=@cTip and @gnumar=@cnumar and 
		((@gTip=''CM'' and @datapcons=1 and @cdata between dateadd(day, 1-day(@gdata), @gdata) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(@gdata), @gdata)))) 
		 or @gdata=@cdata)
		and @gfetch=0
	begin
		set @gtert=@ctert
		set @glm=@clm 
		set @gcom=@ccom
		set @gcont_fact=@ccont_fact
		set @gtip_tva=@ctip_tva
		set @ggest=@cgest
		set @numar_poz=@numar_poz+@semn
		set @tva=@tva+@semn*(case when (left(@ctip,1)=''A''  
			or left(@ctip,1)=''R'') and @cota not in (9, 11) then @tvad else 0 end)
		set @tva9=@tva9+@semn*(case when (left(@ctip,1)=''A''  
			or left(@ctip,1)=''R'') and @cota in (9,11) then @tvad else 0 end)
		set @valoare=@valoare+@semn*(case 
			when @ctip in (''AP'',''AC'',''AS'') then round(convert(decimal(17,5),@cant*@pvanz),@rotunj_n) 
			when @ctip in (''RM'',''RS'') then round(convert(decimal(17,5),@cant*@pstoc),@rotunjr_n) else round(convert(decimal(17,5),@cant*@pstoc), 2) end)
		if @valuta<>'''' set @valoarev=@valoarev+round(convert(decimal(17,5),@semn*(case when @ctip in (''AP'',''AC'',''AS'') 
			then round(convert(decimal(17,5),@pval*(1-@disc/100)+@comppret*@LME/1000)
			+(case when @curs>0 and @cant<>0 then @tvad/@curs/@cant else 0 end),5) 
			else @pval*(1+@disc/100)*(case when @ctip<>''RM'' or @numar_dvi='''' then 1+@cota/100 else 1 end) end)*@cant), 2) 
		if @semn=1 set @gvaluta=@valuta
		if @semn=1 set @gcurs=@curs
		if @semn=1 set @gfact=@fact
		if @semn=1 set @gdf=@df
		if @semn=1 set @gds=@ds
		if @semn=1 and @ctip in (''AP'',''AS'') set @gct4428=@ct4428
		if @semn=1 and @ctip in (''RM'',''RS'') set @ggprim=@gprim
		if @semn=1 set @gstare=(case when @stare=2 or @gstare=2 then 2 when @stare>@gstare then @stare else @gstare end) 
		if @semn=1 and @LME=1 and @urmc2=0 and @comppret=0 and @ctip=''AP'' set @gRetur=1
		fetch next from tmp into @csub,@ctip,@cnumar,@cdata,@ctert,@semn,@cant,@valuta,@curs,@pstoc,@pval,
			@pvanz,@cota,@tvad,@numar_dvi,@fact,@df,@ds,@disc,@LME,@ct4428,@gprim, @stare, @clm, @ccom, @ccont_fact, @ctip_tva, @cgest
		set @gfetch=@@fetch_status
	end
	update doc set valoare=valoare+@valoare, tva_22=tva_22+@tva, tva_11=tva_11+@tva9, 
		valoare_valuta=valoare_valuta+@valoarev, valuta=@gvaluta, curs=@gcurs, factura=@gfact, 
		data_facturii=@gdf, data_scadentei=@gds, numar_pozitii=numar_pozitii+@numar_poz, 
		stare=(case when @gstare=6 or stare=6 then 6 when @gstare=2 or stare=2 then 2 when @gstare>stare then @gstare else stare end) 
		where doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and 
		((@gTip=''CM'' and @datapcons=1 and doc.data between dateadd(day, 1-day(@gdata), @gdata) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(@gdata), @gdata)))) 
		 or doc.data=@gdata)
	update doc set tip_miscare=(case when @gRetur=1 then ''R'' else ''8'' end) 
		where (@gtip in (''AP'',''AS'') and left(@gct4428,4)=''4428'' or @gtip=''AP'' and @gRetur=1)
		and doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata
	update doc set gestiune_primitoare=@ggprim where @gtip in (''RM'',''RS'') 
		and doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata
	update doc set cod_tert=@gtert, loc_munca=@glm, comanda=@gcom, cont_factura=@gcont_fact, cota_tva=(case when tip=''RM'' and numar_DVI<>'''' then 0 else @gtip_tva end), cod_gestiune=@ggest where @gtip in (''RM'',''AP'') 
		and doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata and stare=2
	/* update doc set numar_DVI='''' where @gtip=''RM'' and doc.subunitate=@gsub and doc.tip=@gtip and
		doc.numar=@gnumar and doc.data=@gdata and @accimp=1 and cod_gestiune in (select cod_gestiune from
		gestiuni where tip_gestiune in (''A'',''V''))
	update doc set valoare_valuta=valoare_valuta+(case when dvi.valuta_CIF=@valuta then dvi.valoare_CIF else 0 end), 
		tva_22=tva_22+dvi.tva_CIF+dvi.tva_22+dvi.tva_comis, valoare=valoare+dvi.suma_suprataxe from dvi where 
		@ctip=''RM'' and @numar_dvi<>'''' and doc.subunitate=@gsub and 
		doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata and 
		doc.subunitate=dvi.subunitate and doc.numar= 
		dvi.numar_receptie and doc.numar_dvi=dvi.numar_dvi */
	set @gsub=@csub
	set @gtip=@ctip
	set @gnumar=@cnumar
	set @gdata=@cdata
	set @gtert=@ctert
	set @glm=@clm 
	set @gcom=@ccom
	set @gcont_fact=@ccont_fact
	set @gtip_tva=@ctip_tva
	set @ggest=@cgest
end

close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [docAinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[docAinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[docAinc] on [dbo].[pozdoc] for update,insert,delete with append as
begin 
-- TVA neex. predator
-------------	din tabela par (parametri trimis de Magic):
		declare @adtav_l int, @cont348_l int, @modatim int, @faradesc int, @dafora int, @adtav_n int, @adtava int, @transilva int,
				@rotunjtnx int, @invaddesc int
		set @adtav_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @cont348_l=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''CONT348''),0)
		set @modatim=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''MODATIM''),0)
		set @faradesc=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''FARADESC''),0)
		set @dafora=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DAFORA''),0)
		set @adtav_n=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ADTAV''),0)
		set @adtava=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''ADTAVA''),0)
		set @transilva=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''TRANSILVA''),0)
		set @rotunjtnx=isnull((select top 1 val_numerica from par where tip_parametru=''GE'' and parametru=''ROTUNJTNX''),0)
		set @invaddesc=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''INVADDESC''),0)
-------------
  insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate, tip, numar, data, 
    (case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip=''AE'' then tert else left(numar_DVI,13) end), 
    (case when tip in (''CM'',''TE'') and @invaddesc=0 then rtrim(left(numar_DVI,13)) when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then tert else cont_de_stoc end),
    0, '''', 0, 0, left(max(''TVA neex. pred. ''+tip+'' ''+rtrim(numar)+'' ''+rtrim(gestiune)),50), 
    max(utilizator), max(data_operarii), max(ora_operarii), 0, loc_de_munca, comanda,max(jurnal)
   from inserted a where a.tip in (''CM'',''AP'',''AC'',''TE'',''AE'') and not (a.tip in (''AP'',''AC'') and @modatim=1) 
	and left(a.cont_de_stoc,2) in (''37'',''35'') and ((not (a.tip in (''AP'',''AC'') and left(a.cont_de_stoc,3)=''354'') and @cont348_l=1) or @cont348_l=0)
	and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when a.tip<>''TE'' and @faradesc=1 then ''!'' else ''A'' end),''V'',(case when @adtav_l=1 and a.tip in (''AP'',''AC'') and (@adtav_n=0 or a.tip=''AC'') then ''C'' else ''!'' end))) 
	and not (a.tip=''AP'' and a.gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
	and not (a.tip=''AP'' and @transilva=1 and a.tert in (select tert from terti where tert_extern=1)) 
	and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar
		and data=a.data and cont_debitor=(case when a.tip in (''CM'',''TE'') and @invaddesc=0 or a.tip=''AE'' and @dafora=1 and a.cont_corespondent like ''48%'' then a.cont_de_stoc when a.tip=''AE'' then a.tert else left(a.numar_DVI,13) end) and cont_creditor=(case when a.tip in (''CM'',''TE'') and @invaddesc=0 then rtrim(left(numar_DVI,13)) when a.tip=''AE'' and @dafora=1 and a.cont_corespondent like ''48%'' then a.tert else a.cont_de_stoc end) 
		and loc_de_munca=a.loc_de_munca and comanda=a.comanda and valuta='''') 
	group by a.subunitate, a.tip, a.numar, a.data, (case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip=''AE'' then tert else left(numar_DVI,13) end), (case when tip in (''CM'',''TE'') and @invaddesc=0 then rtrim(left(numar_DVI,13)) when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then tert else cont_de_stoc end), a.loc_de_munca, a.comanda

declare @gsub char(9), @gtip char(2), @gnr char(8), @gdata datetime, @gctd char(13), @gctc char(13), @glm char(9), 
     @gcom char(40), @val float, @gfetch int
declare @sub char(9), @tip char(2), @numar char(8), @data datetime, @contd char(13), @contc char(13), @semn int, 
     @suma float, @locm char(9), @com char(40)

declare tmp cursor for
select subunitate, tip, numar, data, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip=''AE'' then tert else left(numar_DVI,13) end) as contd, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 then rtrim(left(numar_DVI,13)) when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then tert else cont_de_stoc end) as contc, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then -1 else 1 end) as semn, 
(case when tip in (''AP'',''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	then round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), (case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)*cota_tva/(100+(case when tip=''AC'' then cota_tva else 0 end))),@rotunjtnx)), 2) 
	else round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),2) end), 
loc_de_munca, comanda 
from inserted 
where tip in (''CM'',''AP'',''AC'',''TE'',''AE'') and not (tip in (''AP'',''AC'') and @modatim=1) and left(cont_de_stoc,2) in (''37'',''35'') and ((not (tip in (''AP'',''AC'') and left(cont_de_stoc,3)=''354'') and @cont348_l=1) or @cont348_l=0) and not (tip=''AP'' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when tip<>''TE'' and @faradesc=1 then ''!'' else ''A'' end),''V'',(case when @adtav_l=1 and tip in (''AP'',''AC'') and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end))) 
and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
union all
select subunitate, tip, numar, data, 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then cont_de_stoc when tip=''AE'' then tert else left(numar_DVI,13) end), 
(case when tip in (''CM'',''TE'') and @invaddesc=0 then rtrim(left(numar_DVI,13)) when tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then tert else cont_de_stoc end), 
(case when tip in (''CM'',''TE'') and @invaddesc=0 or tip=''AE'' and @dafora=1 and cont_corespondent like ''48%'' then 1 else -1 end), 
(case when tip in (''AP'', ''AC'') and (@adtav_l=1 and (@adtav_n=0 or tip=''AC'') or @adtava=1) and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when @adtav_l=1 then ''C'' else ''!'' end), (case when @adtava=1 then ''A'' else ''!'' end))) 
	then round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), (case when tip=''AP'' then pret_vanzare else pret_cu_amanuntul end)*cota_tva/(100+(case when tip=''AC'' then cota_tva else 0 end))),@rotunjtnx)), 2) 
	else round(convert(decimal(17,5), cantitate*round(convert(decimal(17,5), pret_amanunt_predator*TVA_neexigibil/(100+TVA_neexigibil)),@rotunjtnx)),2) end), 
loc_de_munca, comanda 
from deleted 
where tip in (''CM'',''AP'',''AC'',''TE'',''AE'') and not (tip in (''AP'',''AC'') and @modatim=1) and left(cont_de_stoc,2) in (''37'',''35'') and ((not (tip in (''AP'',''AC'') and left(cont_de_stoc,3)=''354'') and @cont348_l=1) or @cont348_l=0) and not (tip=''AP'' and gestiune in (select cod_gestiune from gestiuni where tip_gestiune=''V'')) 
and gestiune in (select cod_gestiune from gestiuni where tip_gestiune in ((case when tip<>''TE'' and @faradesc=1 then ''!'' else ''A'' end),''V'',(case when @adtav_l=1 and tip in (''AP'',''AC'') and (@adtav_n=0 or tip=''AC'') then ''C'' else ''!'' end))) 
and not (tip=''AP'' and @transilva=1 and tert in (select tert from terti where tert_extern=1)) 
order by subunitate, tip, numar, data, contd, contc, loc_de_munca, comanda

open tmp
fetch next from tmp into @sub,@tip,@numar,@data, @contd,@contc,@semn,@suma, @locm,@com
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdata=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @val=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdata=@data and @gctd=@contd 
		and @gctc=@contc and @glm=@locm and @gcom=@com and @gfetch=0
	begin
		set @val=@val+@suma*@semn
		fetch next from tmp into @sub, @tip, @numar, @data, @contd, @contc, @semn,
			@suma, @locm, @com
		set @gfetch=@@fetch_status
	end
	update pozincon set suma=suma+@val 
	  where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc
		and loc_de_munca=@glm and comanda=@gcom 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr
		and data=@gdata and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm 
		and comanda=@gcom and suma=0 and suma_valuta=0
	set @gsub=@sub
	set @gtip=@tip
	set @gnr=@numar
	set @gdata=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [adocXyinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[adocXyinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[adocXyinc] on [dbo].[pozadoc] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
		declare @cdtva varchar(13), @cctvaned varchar(13), @cneexrec varchar(13)
		set @cdtva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CDTVA''),''''))
		set @cctvaned=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVANED''),''''))
		set @cneexrec=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CNEEXREC''),''''))
-------------
-- cheltuieli TVA nedeductibil SF/FF
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate, a.tip, a.numar_document, a.data,
@cctvaned,
max(case when a.tip=''FF'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.tip=''FF'' and a.cont_cred like ''408%'' then @cneexrec else @cdtva end),
0, a.valuta, max(a.curs), 0, max(a.explicatii), max(a.utilizator), max(a.data_operarii), max(a.ora_operarii), 0, a.loc_munca, a.comanda, max(a.jurnal)
from inserted a 
where @cctvaned<>'''' and a.tip in (''FF'', ''SF'') and a.stare=2 and a.TVA22<>0
and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar_document and data=a.data and cont_debitor=@cctvaned and cont_creditor=(case when a.tip=''FF'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.tip=''FF'' and a.cont_cred like ''408%'' then @cneexrec else @cdtva end) and loc_de_munca=a.loc_munca and comanda=a.comanda and valuta=a.valuta and numar_pozitie=0)
group by a.subunitate, a.tip, a.numar_document, a.data, (case when a.tip=''FF'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.tip=''FF'' and a.cont_cred like ''408%'' then @cneexrec else @cdtva end), a.loc_munca, a.comanda, a.valuta

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdat datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40),@gv char(3),@val float,@valv float,@gcurs float,@gf int,@sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int,@suma float,@sumav float,@valuta char(3),@curs float,@locm char(9),@com char(40),@gp float,@p float

declare tmp cursor for
select a.subunitate, a.tip, a.numar_document, a.data, @cctvaned as cont_deb, (case when a.tip=''FF'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.tip=''FF'' and a.cont_cred like ''408%'' then @cneexrec else @cdtva end) as cont_cred, 1, a.TVA22, (case when a.tip=''FF'' then a.dif_TVA else 0 end), a.valuta, a.curs, a.loc_munca, a.comanda, 0 as nrp 
from inserted a
where @cctvaned<>'''' and a.tip in (''FF'', ''SF'') and a.stare=2 and a.TVA22<>0
union all 
select a.subunitate, a.tip, a.numar_document, a.data, @cctvaned as cont_deb, (case when a.tip=''FF'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.tip=''FF'' and a.cont_cred like ''408%'' then @cneexrec else @cdtva end) as cont_cred, -1, a.TVA22, (case when a.tip=''FF'' then a.dif_TVA else 0 end), a.valuta, a.curs, a.loc_munca, a.comanda, 0 as nrp 
from deleted a
where @cctvaned<>'''' and a.tip in (''FF'', ''SF'') and a.stare=2 and a.TVA22<>0
/*order by a.subunitate, a.tip, a.numar_document, a.data, a.cont_deb, a.cont_cred, a.loc_munca, a.comanda, a.valuta, nrp*/
order by 1, 2, 3, 4, 5, 6, 12, 13, 10, 14

open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@sumav,@valuta,@curs,@locm,@com,@p
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdat=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gv=@valuta
set @gp=@p
set @gf=@@fetch_status
while @gf=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdat=@data and @gctd=@contd and @gctc=@contc and @glm=@locm and @gcom=@com and @gv=@valuta and @gp=@p and @gf=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @semn=1 set @gcurs=@curs
		fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@sumav,@valuta,@curs,@locm,@com,@p
		set @gf=@@fetch_status
	end
	update pozincon set suma=suma+@val,suma_valuta=suma_valuta+@valv,curs=@gcurs 
	where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdat and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv and numar_pozitie=@gp 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdat and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv and numar_pozitie=@gp and suma=0 and suma_valuta=0
	set @gtip=@tip
	set @gnr=@numar
	set @gdat=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gv=@valuta
	set @gp=@p
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [adocXinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[adocXinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[adocXinc] on [dbo].[pozadoc] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @cdtva varchar(13), @cctva varchar(13),	@cneexrec varchar(13), @neexav int, @lrmz int
	set @cdtva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CDTVA''),''''))
	set @cctva=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CCTVA''),''''))
	set @cneexrec=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru=''GE'' and parametru=''CNEEXREC''),''''))
	set @neexav=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''NEEXAV''),0)
	set @lrmz=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''LRMZ''),0)
-------------
-- TVA
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate,tip,numar_document,data,
max(case when tip=''FF'' and tert_beneficiar<>'''' then tert_beneficiar when cont_deb like ''419%'' and tip<>''FB'' then @cctva when tip=''FF'' and cont_cred like ''408%'' then @cneexrec when tip in (''FF'',''SF'')or tip in (''IF'',''FB'')and stare=1 then @cdtva else cont_deb end),
max(case when tip=''FB'' and tert_beneficiar<>'''' then tert_beneficiar when tip in (''SF'',''FF'')and stare=1 then @cctva when tip in (''FF'',''SF'')then cont_cred when cont_deb like ''419%'' or tip=''FB'' and cont_deb like ''418%'' then @cneexrec else @cctva end),
0,valuta,max(curs),0,max(explicatii),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_munca,comanda,max(jurnal)
from inserted a where not (tip in (''IF'',''FB'')and stare=2)and (TVA22<>0 or dif_TVA<>0)and tip not in (''CB'',''CF'')and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar_document and data=a.data and cont_debitor=(case when a.tip=''FF'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.cont_deb like ''419%'' then @cctva when a.tip=''FF'' and a.cont_cred like ''408%'' then @cneexrec when a.tip in (''FF'',''SF'')or a.tip in (''IF'',''FB'')and a.stare=1 then @cdtva else a.cont_deb end)and cont_creditor=(case when a.tip=''FB'' and a.tert_beneficiar<>'''' then a.tert_beneficiar when a.tip in (''SF'',''FF'')and a.stare=1 then @cctva when a.tip in (''FF'',''SF'')then a.cont_cred when a.cont_deb like ''419%'' or a.tip=''FB'' and a.cont_deb like ''418%'' then @cneexrec else @cctva end)and loc_de_munca=a.loc_munca and comanda=a.comanda and valuta=a.valuta and numar_pozitie=0)
group by subunitate,tip,numar_document,data,(case when tip=''FF'' and tert_beneficiar<>'''' then tert_beneficiar when cont_deb like ''419%'' then ''4427'' when tip=''FF'' and cont_cred like ''408%'' then ''4428'' when (tip in (''FF'',''SF''))
or tip in (''IF'',''FB'')and stare=1 then ''4426'' else cont_deb end),(case when tip=''FB'' and tert_beneficiar<>'''' then tert_beneficiar when tip in (''SF'',''FF'')and stare=1 then ''4427'' when tip in (''FF'',''SF'')then cont_cred when cont_deb like ''419%'' 
or tip=''FB'' and cont_deb like ''418%'' then ''4428'' else ''4427'' end),loc_munca,comanda,valuta
-- TVA 2
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate,tip,numar_document,data,
max(case when tip in (''SF'',''CF'')then @cdtva when @neexav=1 and tip=''CB'' then cont_deb else @cneexrec end),max(case when tip in (''xIF'',''CB'')then @cctva when tip=''IF'' or @neexav=1 and tip=''CF'' then cont_cred else @cneexrec end),0,'''',0,0,max(explicatii),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_munca,comanda,max(jurnal)
from inserted a where not (tip=''IF'' and stare=2)and (TVA22<>0 or dif_TVA<>0)and tip in (''SF'',''IF'',''CB'',''CF'')and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar_document and data=a.data and cont_debitor=(case when a.tip in (''SF'',''CF'')then @cdtva when @neexav=1 and tip=''CB'' then cont_deb else @cneexrec end)and cont_creditor=(case when a.tip in (''xIF'',''CB'')then @cctva when tip=''IF'' or @neexav=1 and tip=''CF'' then cont_cred else @cneexrec end)and loc_de_munca=a.loc_munca and comanda=a.comanda and valuta='''' and numar_pozitie=0)
group by subunitate,tip,numar_document,data,cont_deb,cont_cred,loc_munca,comanda

--LeasingROM
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate,tip,numar_document,data,max(''472.''+left(tert,9)),''706.1'',0,'''',0,0,max(explicatii),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_munca,comanda,max(jurnal)
from inserted a
where @lrmz=1 and tip=''IF'' and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar_document and data=a.data and cont_debitor=''472.''+left(tert,9)and cont_creditor=''706'' and loc_de_munca=a.loc_munca and comanda=a.comanda and valuta=a.valuta)
group by subunitate,tip,numar_document,data,cont_deb,cont_cred,loc_munca,comanda,valuta

declare @gsub char(9),@gtip char(2),@gnr char(8),@gdat datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40),@gv char(3),@val float,@valv float,@gcurs float,@gf int,@sub char(9),@tip char(2),@numar char(8),@data datetime,@contd char(13),@contc char(13),@semn int,@suma float,@sumav float,@valuta char(3),@curs float,@locm char(9),@com char(40),@gp float,@p float

declare tmp cursor for
select subunitate,tip,numar_document,data,
(case when tip=''FF'' and tert_beneficiar<>'''' then tert_beneficiar when cont_deb like ''419%'' and tip<>''FB'' then @cctva when tip=''FF'' and cont_cred like ''408%'' then @cneexrec when (tip in (''FF'',''SF''))or (tip in (''IF'',''FB'')and stare=1)then @cdtva else cont_deb end)as cont_deb,
(case when tip=''FB'' and tert_beneficiar<>'''' then tert_beneficiar when tip in (''SF'',''FF'')and stare=1 then @cctva when tip in (''FF'',''SF'')then cont_cred when cont_deb like ''419%'' or tip=''FB'' and cont_deb like ''418%'' then @cneexrec else @cctva end)as cont_cred,
1,(case when tip in (''SF'',''xIF'')then dif_TVA else TVA22 end),(case when tip in (''FF'',''FB'')then dif_TVA else 0 end),valuta,curs,loc_munca,comanda,0as nrp 
from inserted where not (tip in (''IF'',''FB'')and stare=2)and (TVA22<>0 or dif_TVA<>0)and tip not in (''CB'',''CF'')
union all 
select subunitate,tip,numar_document,data,(case when tip in (''SF'',''CF'')then @cdtva when @neexav=1 and tip=''CB'' then cont_deb else @cneexrec end),(case when tip in (''xIF'',''CB'')then @cctva when tip=''IF'' or @neexav=1 and tip=''CF'' or tip=''SF'' and cont_deb like ''308%'' then cont_cred else @cneexrec end),1,(case when tip in (''CF'',''CB'')then -1 else 1 end)*TVA22-(case when tip in (''SF'',''IF'')then dif_TVA else 0 end),0,'''',0,loc_munca,comanda,0
from inserted where not (tip=''IF'' and stare=2)and (TVA22<>0 or dif_TVA<>0)and tip in (''SF'',''IF'',''CB'',''CF'')
union all
select subunitate,tip,numar_document,data,''472.''+left(tert,9),''706.1'',1,(case when valuta='''' then suma else suma_valuta*isnull((select curs from facturi where subunitate=inserted.subunitate and tip=0X46 and tert=inserted.tert and factura=inserted.factura_dreapta),0)end),0,'''',0,loc_munca,comanda,0 
from inserted where @lrmz=1 and tip=''IF'' 
union all
select subunitate,tip,numar_document,data,
(case when tip=''FF'' and tert_beneficiar<>'''' then tert_beneficiar when cont_deb like ''419%'' and tip<>''FB'' then @cctva when tip=''FF'' and cont_cred like ''408%'' then @cneexrec when (tip in (''FF'',''SF''))or (tip in (''IF'',''FB'')and stare=1)then @cdtva else cont_deb end),
(case when tip=''FB'' and tert_beneficiar<>'''' then tert_beneficiar when tip in (''SF'',''FF'')and stare=1 then @cctva when tip in (''FF'',''SF'')then cont_cred when cont_deb like ''419%'' or tip=''FB'' and cont_deb like ''418%'' then @cneexrec else @cctva end),
-1,(case when tip in (''SF'',''xIF'')then dif_TVA else TVA22 end),(case when tip in (''FF'',''FB'')then dif_TVA else 0 end),valuta,curs,loc_munca,comanda,0
from deleted where not (tip in (''IF'',''FB'')and stare=2)and (TVA22<>0 or dif_TVA<>0)and tip not in (''CB'',''CF'')
union all 
select subunitate,tip,numar_document,data,(case when tip in (''SF'',''CF'')then @cdtva when @neexav=1 and tip=''CB'' then cont_deb else @cneexrec end),(case when tip in (''xIF'',''CB'')then @cctva when tip=''IF'' or @neexav=1 and tip=''CF'' or tip=''SF'' and cont_deb like ''308%'' then cont_cred else @cneexrec end),-1,(case when tip in (''CF'',''CB'')then -1 else 1 end)*TVA22-(case when tip in (''SF'',''IF'')then dif_TVA else 0 end),0,'''',0,loc_munca,comanda,0from deleted where not (tip=''IF'' and stare=2)and (TVA22<>0 or dif_TVA<>0)and tip in (''SF'',''IF'',''CB'',''CF'')
union all
select subunitate,tip,numar_document,data,''472.''+left(tert,9),''706.1'',-1,(case when valuta='''' then suma else suma_valuta*isnull((select curs from facturi where subunitate=deleted.subunitate and tip=0X46 and tert=deleted.tert and factura=deleted.factura_dreapta),0)end),0,'''',0,loc_munca,comanda,0 
from deleted where @lrmz=1 and tip=''IF'' 
order by subunitate,tip,numar_document,data,cont_deb,cont_cred,loc_munca,comanda,valuta,nrp

open tmp
fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@sumav,@valuta,@curs,@locm,@com,@p
set @gsub=@sub
set @gtip=@tip
set @gnr=@numar
set @gdat=@data
set @gctd=@contd
set @gctc=@contc
set @glm=@locm
set @gcom=@com
set @gv=@valuta
set @gp=@p
set @gf=@@fetch_status
while @gf=0
begin
	set @val=0
	set @valv=0
	set @gcurs=0
	while @gsub=@sub and @gtip=@tip and @gnr=@numar and @gdat=@data and @gctd=@contd and @gctc=@contc and @glm=@locm and @gcom=@com and @gv=@valuta and @gp=@p and @gf=0
	begin
		set @val=@val+@suma*@semn
		set @valv=@valv+@sumav*@semn
		if @semn=1 set @gcurs=@curs
		fetch next from tmp into @sub,@tip,@numar,@data,@contd,@contc,@semn,@suma,@sumav,@valuta,@curs,@locm,@com,@p
		set @gf=@@fetch_status
	end
	update pozincon set suma=suma+@val,suma_valuta=suma_valuta+@valv,curs=@gcurs 
	where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdat and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv and numar_pozitie=@gp 
	delete from pozincon where subunitate=@gsub and tip_document=@gtip and numar_document=@gnr and data=@gdat and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv and numar_pozitie=@gp and suma=0 and suma_valuta=0
	set @gtip=@tip
	set @gnr=@numar
	set @gdat=@data
	set @gctd=@contd
	set @gctc=@contc
	set @glm=@locm
	set @gcom=@com
	set @gv=@valuta
	set @gp=@p
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [adocinc]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[adocinc]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[adocinc] on [dbo].[pozadoc] for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
		declare @ifn int
		set @ifn=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''IFN''),0)
-------------
--baza
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select a.subunitate,tip,numar_document,data,(case when suma<0 and (tip=''FF'' and (left(cont_deb,1)=''7'' or left(cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or tip=''FB'' and (left(cont_cred,1)=''6'' or left(cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then cont_cred when tip=''FF'' and cont_dif<>'''' then cont_dif else cont_deb end),(case when suma<0 and (tip=''FF'' and (left(cont_deb,1)=''7'' or left(cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or tip=''FB'' and (left(cont_cred,1)=''6'' or left(cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then (case when tip=''FF'' and cont_dif<>'''' then cont_dif else cont_deb end) else cont_cred end),0,valuta,max(curs),0,max(explicatii),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_munca,comanda,max(jurnal)
from inserted a
left join conturi cd on cd.subunitate=a.subunitate and cd.cont=a.cont_deb
left join conturi cc on cc.subunitate=a.subunitate and cc.cont=a.cont_cred
where not (tip=''CO'' and cont_deb='''' and cont_cred='''') and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar_document and data=a.data and cont_debitor=(case when a.suma<0 and (a.tip=''FF'' and (left(a.cont_deb,1)=''7'' or left(a.cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or a.tip=''FB'' and (left(a.cont_cred,1)=''6'' or left(a.cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then a.cont_cred when a.tip=''FF'' and a.cont_dif<>'''' then a.cont_dif else a.cont_deb end) and cont_creditor=(case when a.suma<0 and (a.tip=''FF'' and (left(a.cont_deb,1)=''7'' or left(a.cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or a.tip=''FB'' and (left(a.cont_cred,1)=''6'' or left(a.cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then (case when a.tip=''FF'' and a.cont_dif<>'''' then a.cont_dif else a.cont_deb end) else a.cont_cred end) and loc_de_munca=a.loc_munca and comanda=a.comanda and valuta=a.valuta and numar_pozitie=0)
group by a.subunitate,tip,numar_document,data,(case when suma<0 and (tip=''FF'' and (left(cont_deb,1)=''7'' or left(cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or tip=''FB'' and (left(cont_cred,1)=''6'' or left(cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then cont_cred when tip=''FF'' and cont_dif<>'''' then cont_dif else cont_deb end),(case when suma<0 and (tip=''FF'' and (left(cont_deb,1)=''7'' or left(cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or tip=''FB'' and (left(cont_cred,1)=''6'' or left(cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then (case when tip=''FF'' and cont_dif<>'''' then cont_dif else cont_deb end) else cont_cred end),loc_munca,comanda,valuta
--dif. curs/poz. interm. FF
insert into pozincon (Subunitate,Tip_document,Numar_document,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Loc_de_munca,Comanda,Jurnal)
select subunitate,tip,numar_document,data,(case when tip=''FF'' and cont_dif<>'''' then (case when suma<0 and left(cont_deb,1)=''7'' then cont_dif else cont_deb end) when left(cont_dif,1) in (''6'',''3'') then cont_dif else cont_deb end),(case when tip=''FF'' and cont_dif<>'''' then (case when suma<0 and left(cont_deb,1)=''7'' then cont_deb else cont_dif end) when left(cont_dif,1)=''7'' then cont_dif else cont_cred end),
0,'''',0,0,max(explicatii),max(utilizator),max(data_operarii),max(ora_operarii),0,loc_munca,comanda,max(jurnal)
from inserted a
where (suma_dif<>0 or tip=''FF'' and cont_dif<>'''') and not exists (select 1 from pozincon where subunitate=a.subunitate and tip_document=a.tip and numar_document=a.numar_document and data=a.data and cont_debitor=(case when a.tip=''FF'' and a.cont_dif<>'''' then (case when a.suma<0 and left(a.cont_deb,1)=''7'' then a.cont_dif else a.cont_deb end) when left(a.cont_dif,1) in (''6'',''3'') then a.cont_dif else a.cont_deb end) and cont_creditor=(case when a.tip=''FF'' and a.cont_dif<>'''' then (case when a.suma<0 and left(a.cont_deb,1)=''7'' then a.cont_dif else a.cont_deb end) when a.cont_dif like ''7%'' then a.cont_dif else a.cont_cred end) and loc_de_munca=a.loc_munca and comanda=a.comanda and valuta='''' and numar_pozitie=0)
group by subunitate,tip,numar_document,data,(case when tip=''FF'' and cont_dif<>'''' then (case when suma<0 and left(cont_deb,1)=''7'' then cont_dif else cont_deb end) when left(cont_dif,1) in (''6'',''3'') then cont_dif else cont_deb end),(case when tip=''FF'' and cont_dif<>'''' then (case when suma<0 and left(cont_deb,1)=''7'' then cont_deb else cont_dif end) when left(cont_dif,1)=''7'' then cont_dif else cont_cred end),loc_munca,comanda

declare @gsb char(9),@gtip char(2),@gnr char(8),@gdat datetime,@gctd char(13),@gctc char(13),@glm char(9),@gcom char(40),@gv char(3),@val float,@valv float,@gcurs float,@gfetch int,@sb char(9),@tip char(2),@nr char(8),@data datetime,@ctd char(13),@ctc char(13),@semn int,@suma float,@sumav float,@valuta char(3),@curs float,@lm char(9),@com char(40),@gp float,@p float,@invers int,@cti char(13)

declare tmp cursor for
select a.subunitate,tip,numar_document,data,(case when tip=''FF'' and cont_dif<>'''' then cont_dif else cont_deb end),cont_cred,1,suma+(case when tip=''SF'' and left(cont_deb,3)<>''308'' or 1=0 and tip=''IF'' then TVA22-dif_TVA else 0 end)-(case when tip in (''CF'',''SF'',''CO'') and left(cont_dif,1) in (''6'',''3'') or tip in (''CB'',''IF'') and cont_dif like ''7%'' then suma_dif else 0 end),(case when @ifn=1 and tip=''CB'' and suma_valuta=0 then achit_fact else suma_valuta+(case when tip=''IF'' and curs>0 then TVA22/curs else 0 end) end),valuta,curs,loc_munca,comanda,0 as nrp,(case when suma<0 and (tip=''FF'' and (left(cont_deb,1)=''7'' or left(cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or tip=''FB'' and (left(cont_cred,1)=''6'' or left(cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then 1 else 0 end) as inversare
from inserted a
left join conturi cd on cd.subunitate=a.subunitate and cd.cont=a.cont_deb
left join conturi cc on cc.subunitate=a.subunitate and cc.cont=a.cont_cred
union all
select subunitate,tip,numar_document,data,(case when tip=''FF'' and cont_dif<>'''' then cont_deb when left(cont_dif,1) in (''6'',''3'') then cont_dif else cont_deb end),(case when tip=''FF'' and cont_dif<>'''' then cont_dif when cont_dif like ''7%'' then cont_dif else cont_cred end),1,(case when tip=''FF'' and cont_dif<>'''' then suma else suma_dif end),(case when tip=''FF'' and cont_dif<>'''' then suma_valuta else 0 end),(case when tip=''FF'' and cont_dif<>'''' then valuta else '''' end),(case when tip=''FF'' and cont_dif<>'''' then curs else 0 end),loc_munca,comanda,0,(case when tip=''FF'' and cont_dif<>'''' and suma<0 and left(cont_deb,1)=''7'' then 1 else 0 end)
from inserted where (suma_dif<>0 or tip=''FF'' and cont_dif<>'''')
union all
select a.subunitate,tip,numar_document,data,(case when tip=''FF'' and cont_dif<>'''' then cont_dif else cont_deb end),cont_cred,-1,suma+(case when tip=''SF'' and left(cont_deb,3)<>''308'' or 1=0 and tip=''IF'' then TVA22-dif_TVA else 0 end)-(case when tip in (''CF'',''SF'',''CO'') and left(cont_dif,1) in (''6'',''3'') or tip in (''CB'',''IF'') and cont_dif like ''7%'' then suma_dif else 0 end),(case when @ifn=1 and tip=''CB'' and suma_valuta=0 then achit_fact else suma_valuta+(case when tip=''IF'' and curs>0 then TVA22/curs else 0 end) end),valuta,curs,loc_munca,comanda,0,(case when suma<0 and (tip=''FF'' and (left(cont_deb,1)=''7'' or left(cont_deb,1)=''6'' and isnull(cd.tip_cont,'''')=''P'') or tip=''FB'' and (left(cont_cred,1)=''6'' or left(cont_cred,1)=''7'' and isnull(cc.tip_cont,'''')=''A'')) then 1 else 0 end) as inversare
from deleted a
left join conturi cd on cd.subunitate=a.subunitate and cd.cont=a.cont_deb
left join conturi cc on cc.subunitate=a.subunitate and cc.cont=a.cont_cred
union all
select subunitate,tip,numar_document,data,(case when tip=''FF'' and cont_dif<>'''' then cont_deb when left(cont_dif,1) in (''6'',''3'') then cont_dif else cont_deb end),(case when tip=''FF'' and cont_dif<>'''' then cont_dif when cont_dif like ''7%'' then cont_dif else cont_cred end),-1,(case when tip=''FF'' and cont_dif<>'''' then suma else suma_dif end),(case when tip=''FF'' and cont_dif<>'''' then suma_valuta else 0 end),(case when tip=''FF'' and cont_dif<>'''' then valuta else '''' end),(case when tip=''FF'' and cont_dif<>'''' then curs else 0 end),loc_munca,comanda,0,(case when tip=''FF'' and cont_dif<>'''' and suma<0 and left(cont_deb,1)=''7'' then 1 else 0 end)
from deleted where (suma_dif<>0 or tip=''FF'' and cont_dif<>'''')
order by 1,2,3,4,5,6,12,13,10,14

open tmp
fetch next from tmp into @sb,@tip,@nr,@data,@ctd,@ctc,@semn,@suma,@sumav,@valuta,@curs,@lm,@com,@p,@invers
if @invers=1
	select @cti=@ctd,@ctd=@ctc,@ctc=@cti,@suma=-@suma,@sumav=-@sumav
select @gsb=@sb,@gtip=@tip,@gnr=@nr,@gdat=@data,@gctd=@ctd,@gctc=@ctc,@glm=@lm,@gcom=@com,@gv=@valuta,@gp=@p,@gfetch=@@fetch_status
while @gfetch=0
begin
	select @val=0,@valv=0,@gcurs=0
	while @gsb=@sb and @gtip=@tip and @gnr=@nr and @gdat=@data and @gctd=@ctd and @gctc=@ctc and @glm=@lm and @gcom=@com and @gv=@valuta and @gp=@p and @gfetch=0
	begin
		select @val=@val+@suma*@semn,@valv=@valv+@sumav*@semn
		if @semn=1 set @gcurs=@curs
		fetch next from tmp into @sb,@tip,@nr,@data,@ctd,@ctc,@semn,@suma,@sumav,@valuta,@curs,@lm,@com,@p,@invers
		set @gfetch=@@fetch_status
		if @invers=1
			select @cti=@ctd,@ctd=@ctc,@ctc=@cti,@suma=-@suma,@sumav=-@sumav
	end
	update pozincon set suma=suma+@val,suma_valuta=suma_valuta+@valv,curs=@gcurs
	where subunitate=@gsb and tip_document=@gtip and numar_document=@gnr and data=@gdat and cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv and numar_pozitie=@gp
	delete from pozincon where subunitate=@gsb and tip_document=@gtip and numar_document=@gnr and data=@gdat and numar_pozitie=@gp and (cont_debitor=cont_creditor or cont_debitor=@gctd and cont_creditor=@gctc and loc_de_munca=@glm and comanda=@gcom and valuta=@gv and suma=0 and suma_valuta=0)
	select @gtip=@tip,@gnr=@nr,@gdat=@data,@gctd=@ctd,@gctc=@ctc,@glm=@lm,@gcom=@com,@gv=@valuta,@gp=@p
end
close tmp
deallocate tmp
end'
GO
/****** Object:  Trigger [adocfacst]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[adocfacst]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[adocfacst] on [dbo].[pozadoc] for update,insert,delete as 
begin
insert into facturi select subunitate,max(loc_munca),(case when tip in (''CB'',''IF'',''FB'') then 0x46 else 0x54 end),factura_stinga,tert,max(data_fact),max(data_scad),0,0,0,max(valuta),max(curs),0,0,0,max(cont_deb),0,0,max(comanda),max(data_fact) 
from inserted ins where tip<>''FF'' and factura_stinga not in (select factura from facturi where subunitate=ins.subunitate and tert=ins.tert and tip=(case when ins.tip in (''CB'',''IF'',''FB'') then 0x46 else 0x54 end))
group by subunitate,(case when tip in (''CB'',''IF'',''FB'') then 0x46 else 0x54 end),tert,factura_stinga

declare @val float,@valv float,@vtva float,@vtva9 float,@ach float,@achv float,@dataultachit datetime,@ct char(13),@csub char(9),@ctip char(2),@data datetime,@ctert char(13),@cfact char(20),@semn int,@s float,@sv float,
@sdif float,@tva11 float,@tva22 float,@vlt char(3),@curs float,@achf float,@dift float,@ds datetime,@TVAv float,@gct char(13),@gsub char(9),@gtip char(2),@gt char(13),@gf char(20),@tipf binary,@gds datetime,@gfetch int,@gcurs float,
@dataf datetime, @gdataf datetime, @lm char(9), @glm char(9), @comanda char(40), @gcomanda char(40)

declare tmp cursor for
select subunitate,tip,data,tert,factura_stinga as factura,1,suma,suma_valuta,(case when tip in (''CF'',''SF'',''CO'') and left(cont_dif,1) in (''6'',''3'') then -suma_dif else suma_dif end),
tva11,(case when tip in (''IF'',''FB'') and stare in (1,2) then 0 else tva22 end),valuta,curs,achit_fact,dif_TVA,data_scad,
(case when tip=''C3'' or tip in (''IF'',''FB'') and stare in (1,2) or tip=''IF'' and isnumeric(tert_beneficiar)=0 then 0 when tip=''FB'' then dif_TVA else convert(float,tert_beneficiar) end),cont_deb, data_fact, loc_munca, comanda
from inserted where tip<>''FF''
union all
select subunitate,tip,data,tert,factura_stinga,-1,suma,suma_valuta,(case when tip in (''CF'',''SF'',''CO'') and left(cont_dif,1) in (''6'',''3'') then -suma_dif else suma_dif end),
tva11,(case when tip in (''IF'',''FB'') and stare in (1,2) then 0 else tva22 end),valuta,curs,achit_fact,dif_TVA,data_scad,
(case when tip=''C3'' or tip in (''IF'',''FB'') and stare in (1,2) or tip=''IF'' and isnumeric(tert_beneficiar)=0 then 0 when tip=''FB'' then dif_TVA else convert(float,tert_beneficiar) end),cont_deb, data_fact, loc_munca, comanda
from deleted where tip<>''FF''
order by subunitate,tip,tert,factura
open tmp
fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
set @gsub=@csub
set @gt=@ctert
set @gf=@cfact
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @val=0
set @valv=0
set @vtva=0
set @vtva9=0
set @ach=0
set @achv=0
set @dataultachit=''''
set @gct=''''
set @gds=@ds
set @gcurs=@curs
set @gdataf=''''
set @glm=''''
set @gcomanda=''''
while @gsub=@csub and @cTip=@gTip and @gt=@ctert and @gf=@cfact and @gfetch=0
begin
	if @ctip in (''CB'',''IF'',''FB'') set @tipf=0x46 else set @tipf=0x54
	if @ctip=''CO'' or @ctip=''C3'' begin
		set @ach=@ach+@s*@semn+@semn*@sdif
		if @vlt<>'''' set @achv=@achv+@semn*@sv
	end
	if @ctip=''CF'' 
		if @vlt='''' set @ach=@ach+@s*@semn
		else begin
		set @ach=@ach+@s*@semn+@semn*@sdif
		set @achv=@achv+@achf*@semn
		end
	if @ctip=''CB'' begin
		if @vlt='''' 
			set @ach=@ach-@s*@semn
		else begin
		set @ach=@ach-@s*@semn
		set @achv=@achv-@sv*@semn
		end
		if @semn=1 set @gds=@ds
	end
	if @ctip=''SF'' begin
		set @ach=@ach+@s*@semn+@semn*@tva22-@semn*@dift
		if @vlt<>'''' 
		begin
		set @ach=@ach+@sdif*@semn
		set @achv=@achv+@semn*(@achf+@TVAv)
		set @achv=@achv-(case when @tva22<>0 then @semn*(@dift/@tva22)*@TVAv else 0 end)
		end
	end
	if @ctip=''IF'' begin
		set @val=@val+@s*@semn
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @vlt<>'''' 
			set @valv=@valv+@sv*@semn
		if @vlt<>'''' 
			set @valv=@valv+@TVAv*@semn
		if @semn=1 set @gds=@ds
	end
	if @ctip=''FB'' begin
		set @val=@val+@semn*@s
		set @valv=@valv+@semn*@sv+@semn*@TVAv
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @semn=1 set @gds=@ds
		if @semn=1 set @gcurs=@curs
	end
	if @semn=1 and @ctip in (''CO'',''CF'',''CB'',''SF'') set @dataultachit=@data
	if @semn=1 and @ctip in (''CB'',''IF'',''FB'') set @gct=@ct
	if @semn=1 set @gdataf=(case when @gdataf<=''01/01/1901'' or @dataf<@gdataf then @dataf else @gdataf end)
	if @semn=1 set @glm=(case when @lm<>'''' then @lm else @glm end)
	if @semn=1 set @gcomanda=(case when @comanda<>'''' then @comanda else @gcomanda end)
	fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
	set @gfetch=@@fetch_status
end
update facturi set valoare=valoare+@val,tva_22=tva_22+@vtva,tva_11=tva_11+@vtva9,achitat=achitat+@ach,
sold=sold+@val+@vtva+@vtva9-@ach,data_ultimei_achitari=@dataultachit,
cont_de_tert=(case when @gct='''' then cont_de_tert else @gct end),
data_scadentei=(case when @gtip in (''IF'',''FB'',''CB'') then @gds else data_scadentei end),
data=(case when @gdataf>''01/01/1901'' and @gdataf<data then @gdataf else data end),
loc_de_munca=(case when loc_de_munca='''' or @gdataf>''01/01/1901'' and @gdataf<=data and @glm<>'''' then @glm else loc_de_munca end),
comanda=(case when comanda='''' or @gdataf>''01/01/1901'' and @gdataf<=data and @gcomanda<>'''' then @gcomanda else comanda end)
where subunitate=@gsub and tip=@tipf and tert=@gt and factura=@gf

update facturi set valoare_valuta=valoare_valuta+@valv,achitat_valuta=achitat_valuta+@achv,
sold_valuta=sold_valuta+@valv-@achv,curs=(case when @gtip=''FB'' then @gcurs else curs end)
from terti t where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gt and facturi.factura=@gf 
and facturi.subunitate=t.subunitate and facturi.tert=t.tert and t.tert_extern=1
set @gt=@ctert
set @gsub=@csub
set @gf=@cfact
set @gtip=@ctip
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [adocfacdr]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[adocfacdr]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[adocfacdr] on [dbo].[pozadoc] for update,insert,delete as 
begin
insert into facturi select subunitate,max(loc_munca),(case when tip in (''CF'',''SF'',''FF'') then 0x54 else 0x46 end),factura_dreapta,(case when tip=''C3'' then tert_beneficiar else tert end),max(data_fact),max(data_scad),0,0,0,max(valuta),max(curs),0,0,0,max(cont_cred),0,0,max(comanda),max(data_fact) 
from inserted ins where tip<>''FB'' and factura_dreapta not in (select factura from facturi where subunitate=ins.subunitate and tert=(case when ins.tip=''C3'' then ins.tert_beneficiar else ins.tert end) and tip=(case when ins.tip in (''CF'',''SF'',''FF'') then 0x54 else 0x46 end))
group by subunitate,(case when tip in (''CF'',''SF'',''FF'') then 0x54 else 0x46 end),factura_dreapta,(case when tip=''C3'' then tert_beneficiar else tert end)

declare @val float,@valv float,@vtva float,@vtva9 float,@ach float,@achv float,@dataultachit datetime,@ct char(13),@csub char(9),@ctip char(2),@data datetime,@ctert char(13),@cfact char(20),@semn int,@s float,@sv float,
@sdif float,@tva11 float,@tva22 float,@vlt char(3),@curs float,@achf float,@dift float,@ds datetime,@TVAv float,@diftvaval float,@gct char(13),@gsub char(9),@gtip char(2),@gt char(13),@gf char(20),@tipf binary,@gds datetime,@gfetch int,@gcurs float,
@dataf datetime, @gdataf datetime, @lm char(9), @glm char(9), @comanda char(40), @gcomanda char(40)

declare tmp cursor for
select subunitate,tip,data,(case when tip=''C3'' then tert_beneficiar else tert end) as tert,factura_dreapta as factura,1,suma,suma_valuta,
(case when tip in (''CB'',''IF'') and left(cont_dif,1)=''7'' then -suma_dif else suma_dif end) as suma_dif,tva11,(case when tip in (''SF'',''FF'') and stare=1 then 0 else tva22 end),valuta,curs,achit_fact,dif_TVA,data_scad,
(case when tip=''C3'' or tip in (''FF'',''SF'') and stare=1 or tip=''SF'' and isnumeric(tert_beneficiar)=0 then 0 when tip=''FF'' then dif_TVA else convert(float,tert_beneficiar) end),cont_cred, data_fact, loc_munca, comanda
from inserted where tip<>''FB'' 
union all
select subunitate,tip,data,(case when tip=''C3'' then tert_beneficiar else tert end),factura_dreapta,-1,suma,suma_valuta,
(case when tip in (''CB'',''IF'') and left(cont_dif,1)=''7'' then -suma_dif else suma_dif end),tva11,(case when tip in (''SF'',''FF'') and stare=1 then 0 else tva22 end),valuta,curs,achit_fact,dif_TVA,data_scad,
(case when tip=''C3'' or tip in (''FF'',''SF'') and stare=1 or tip=''SF'' and isnumeric(tert_beneficiar)=0 then 0 when tip=''FF'' then dif_TVA else convert(float,tert_beneficiar) end),cont_cred, data_fact, loc_munca, comanda
from deleted where tip<>''FB''
order by subunitate,tip,tert,factura
open tmp
fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
set @gsub=@csub
set @gt=@ctert
set @gf=@cfact
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @val=0
set @valv=0
set @vtva=0
set @vtva9=0
set @ach=0
set @achv=0
set @dataultachit=''''
set @gct=''''
set @gds=@ds
set @gcurs=@curs
set @gdataf=''''
set @glm=''''
set @gcomanda=''''
while @gsub=@csub and @cTip=@gTip and @gt=@ctert and @gf=@cfact and @gfetch=0
begin
	if @ctip in (''CF'',''SF'',''FF'') set @tipf=0x54 else set @tipf=0x46
	if @ctip=''CO'' or @ctip=''C3'' begin
		set @ach=@ach+@s*@semn
		if @vlt<>'''' 
			set @achv=@achv+@semn*@sv
	end
	if @ctip=''CF'' begin
		if @vlt='''' set @ach=@ach-(@s-(case when @cfact in (select factura from factimpl where subunitate=@gsub and tert=@gt and tip=0X54) then @tva22 else 0 end))*@semn
		else
		begin
		set @ach=@ach-@s*@semn
		set @achv=@achv-@sv*@semn
		end
		if @semn=1 set @gds=@ds
	end
	if @ctip=''CB'' 
		if @vlt='''' set @ach=@ach+@s*@semn
		else begin
		set @ach=@ach+@s*@semn+@semn*@sdif
		set @achv=@achv+@achf*@semn
		end
	if @ctip=''SF'' begin
		set @val=@val+@s*@semn
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @vlt<>'''' set @valv=@valv+@semn*(@sv+@TVAv)
		if @semn=1 set @gds=@ds
	end
	if @ctip=''IF'' begin
		set @ach=@ach+@s*@semn+@semn*@tva22-@semn*@dift
		if @vlt<>'''' 
		begin
		set @ach=@ach+@sdif*@semn
		set @achv=@achv+@achf*@semn
		set @achv=@achv+@TVAv*@semn
		set @achv=@achv-(case when @tva22<>0 then @semn*(@dift/@tva22)*@TVAv else 0 end)
		end
	end
	if @ctip=''FF'' begin
		set @val=@val+@semn*@s
		set @valv=@valv+@semn*@sv+@semn*@TVAv
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @semn=1 set @gds=@ds
		if @semn=1 set @gcurs=@curs
	end
	if @semn=1 and @ctip in (''CO'',''CF'',''CB'',''IF'') set @dataultachit=@data
	if @semn=1 and @ctip in (''CF'',''SF'',''FF'') set @gct=@ct
	if @semn=1 set @gdataf=(case when @gdataf<=''01/01/1901'' or @dataf<@gdataf then @dataf else @gdataf end)
	if @semn=1 set @glm=(case when @lm<>'''' then @lm else @glm end)
	if @semn=1 set @gcomanda=(case when @comanda<>'''' then @comanda else @gcomanda end)
	fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
	set @gfetch=@@fetch_status
end
update facturi set valoare=valoare+@val,tva_22=tva_22+@vtva,tva_11=tva_11+@vtva9,achitat=achitat+@ach,
sold=sold+@val+@vtva+@vtva9-@ach,data_ultimei_achitari=(case when @gtip in (''CB'',''CF'',''CO'',''C3'') then @dataultachit else data_ultimei_achitari end),
cont_de_tert=(case when @gct='''' then cont_de_tert else @gct end),
data_scadentei=(case when @gtip in (''SF'',''FF'',''CF'') then @gds else data_scadentei end),/*valuta='''',curs=0,*/
data=(case when @gdataf>''01/01/1901'' and @gdataf<data then @gdataf else data end),
loc_de_munca=(case when loc_de_munca='''' or @gdataf>''01/01/1901'' and @gdataf<=data and @glm<>'''' then @glm else loc_de_munca end),
comanda=(case when comanda='''' or @gdataf>''01/01/1901'' and @gdataf<=data and @gcomanda<>'''' then @gcomanda else comanda end)
where subunitate=@gsub and tip=@tipf and tert=@gt and factura=@gf

update facturi set valoare_valuta=valoare_valuta+@valv,achitat_valuta=achitat_valuta+@achv,
sold_valuta=sold_valuta+@valv-@achv ,curs=(case when @gtip=''FF'' then @gcurs else curs end)  
from terti t where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gt and facturi.factura=@gf 
and facturi.subunitate=t.subunitate and facturi.tert=t.tert and t.tert_extern=1 	

delete from facturi where @ctip=''FF'' and subunitate=@gsub and tip=@tipf and tert=@gt and factura=@gf 
and valoare=0 and tva_22=0 and tva_11=0 and achitat=0 and valoare_valuta=0 and achitat_valuta=0
set @gt=@ctert
set @gsub=@csub
set @gf=@cfact
set @gtip=@ctip
end
close tmp
deallocate tmp
end
'
GO
/****** Object:  Trigger [adocantet]    Script Date: 12/16/2011 17:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[adocantet]'))
EXEC dbo.sp_executesql @statement = N'--***
/*Pentru creat antet alte documente*/
create trigger [dbo].[adocantet] on [dbo].[pozadoc] for update,insert,delete with append as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @docdef int--, @docdefie int
	set @docdef=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCDEF''),0)
	if (@docdef=1) set @docdef=1-isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCDEFIE''),0) 	
	--set @docdefie=isnull((select top 1 val_logica from par where tip_parametru=''GE'' and parametru=''DOCDEFIE''),0)
	/**	sau :1=1 and :2=0	in expresia de mai jos*/
-------------
insert into adoc (Subunitate,Tip,Numar_document,Data,Tert,Numar_pozitii,Jurnal,Stare)
	select subunitate,tip,numar_document,data,max(tert),0,max (jurnal), max(case when stare=7 or @docdef=1 and stare=2 then stare else 0 end)
	from inserted where numar_document not in 
	(select numar_document from adoc where subunitate=inserted.subunitate 
	and tip=inserted.tip and data=inserted.data) 
	group by subunitate,tip,numar_document,data

/*Pentru calculul nr. de pozitii*/
declare @numar_poz int
declare @csub char(9),@ctip char(2),@cnr char(8),@cdata datetime,@semn int
declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gfetch int

declare tmp cursor for
select subunitate,tip,numar_document,data,1
	from inserted union all
select subunitate,tip,numar_document,data,-1
	from deleted 
order by subunitate,tip,numar_document,data

open tmp
fetch next from tmp into @csub,@ctip,@cnr,@cdata,@semn
set @gsub=@csub
set @gtip=@ctip
set @gnr=@cnr
set @gdata=@cdata
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @numar_poz=0
	while @gsub=@csub and @gtip=@ctip and @gnr=@cnr and @gdata=@cdata and @gfetch=0
	begin
		set @numar_poz=@numar_poz+@semn
		fetch next from tmp into @csub,@ctip,@cnr,@cdata,@semn
		set @gfetch=@@fetch_status
	end
	update adoc set numar_pozitii=numar_pozitii+@numar_poz 
		where adoc.subunitate=@gsub and adoc.tip=@gtip and 
		adoc.numar_document=@gnr and adoc.data=@gdata
	set @gsub=@csub
	set @gtip=@ctip
	set @gnr=@cnr
	set @gdata=@cdata
end

close tmp
deallocate tmp
end'
GO
