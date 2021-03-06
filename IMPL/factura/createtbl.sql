USE [TET]
GO
/****** Object:  Table [dbo].[sysspp]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[sysspd]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[sysspcon]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[sysspa]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[syssmm]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[sysscon]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[seriidocrs]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[selfactachit]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[pvbon]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[prog_plin]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[_pv]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[istfact]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[PozBord]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[combPozd]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[avnefac]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[antetBonuri]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[anexafac]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[adocsters]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[ExpImpExtras]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[pdgrup]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[mismf_nu_sterge]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[misMF]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[ImpExtras]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[impcurs]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[generareplati]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[facturi]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[pozplin]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[incfact]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[factrate]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[factposleg]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[factpos]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[factimpl]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[factext]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[extprogpl]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[docsters]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[docAnalize]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[doc]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[con]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[DVI]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[pozdoc]    Script Date: 12/16/2011 17:06:07 ******/
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
/****** Object:  Table [dbo].[pozadoc]    Script Date: 12/16/2011 17:06:07 ******/
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
