USE [TET]
GO

/****** Object:  Table [dbo].[pozcon1]    Script Date: 12/16/2011 16:10:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[pozcon1](
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
	[Factura] [char](9) NOT NULL,
	[Cant_disponibila] [float] NOT NULL,
	[Cant_aprobata] [float] NOT NULL,
	[Cant_realizata] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Suma_TVA] [float] NOT NULL,
	[Mod_de_plata] [char](8) NOT NULL,
	[UM] [char](1) NOT NULL,
	[Zi_scadenta_din_luna] [smallint] NOT NULL,
	[Explicatii] [char](200) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

insert pozconselect


