
CREATE TABLE [dbo].[nomenclidx](
	[Cod] [char](30) NOT NULL,
	[Tip] [char](1) NOT NULL,
	[Denumire] [char](150) NOT NULL,
	[UM] [char](3) NOT NULL,
	[UM_1] [char](3) NOT NULL,
	[Coeficient_conversie_1] [float] NOT NULL,
	[UM_2] [char](20) NOT NULL,
	[Coeficient_conversie_2] [float] NOT NULL,
	[Cont] [char](13) NOT NULL,
	[Grupa] [char](13) NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Pret_in_valuta] [float] NOT NULL,
	[Pret_stoc] [float] NOT NULL,
	[Pret_vanzare] [float] NOT NULL,
	[Pret_cu_amanuntul] [float] NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Stoc_limita] [float] NOT NULL,
	[Stoc] [float] NOT NULL,
	[Greutate_specifica] [float] NOT NULL,
	[Furnizor] [char](13) NOT NULL,
	[Loc_de_munca] [char](150) NOT NULL,
	[Gestiune] [char](13) NOT NULL,
	[Categorie] [smallint] NOT NULL,
	[Tip_echipament] [char](21) NOT NULL
) ON [PRIMARY]

GO



/****** Object:  Index [Cod]    Script Date: 11/21/2011 12:23:37 ******/
CREATE UNIQUE CLUSTERED INDEX [Cod] ON [dbo].[nomencl] 
(
	[Cod] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

