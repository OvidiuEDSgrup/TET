use [TET]
go

CREATE NONCLUSTERED INDEX [_dta_index_pozdoc_8_313820230__K1_K2_K18_K5_K26_K3_K6_K4_K35_K38_K33_K46_K27_7_9_11] ON [dbo].[pozdoc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Cod_intrare] ASC,
	[Data] ASC,
	[Numar_pozitie] ASC,
	[Numar] ASC,
	[Gestiune] ASC,
	[Cod] ASC,
	[Gestiune_primitoare] ASC,
	[Grupa] ASC,
	[Tert] ASC,
	[Accize_cumparare] ASC,
	[Loc_de_munca] ASC
)
INCLUDE ( [Cantitate],
[Pret_de_stoc],
[Pret_vanzare]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [_dta_index_pozdoc_8_313820230__K2_K1_K5_K3_K26_K35_K38_K4_K6_K18] ON [dbo].[pozdoc] 
(
	[Tip] ASC,
	[Subunitate] ASC,
	[Data] ASC,
	[Numar] ASC,
	[Numar_pozitie] ASC,
	[Gestiune_primitoare] ASC,
	[Grupa] ASC,
	[Cod] ASC,
	[Gestiune] ASC,
	[Cod_intrare] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [_dta_index_pozdoc_8_313820230__K2_K1_K5_K3_K4_K6_K18_K26_7_9] ON [dbo].[pozdoc] 
(
	[Tip] ASC,
	[Subunitate] ASC,
	[Data] ASC,
	[Numar] ASC,
	[Cod] ASC,
	[Gestiune] ASC,
	[Cod_intrare] ASC,
	[Numar_pozitie] ASC
)
INCLUDE ( [Cantitate],
[Pret_de_stoc]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [_dta_index_pozdoc_8_313820230__K2_K1_K5_K3_7_9] ON [dbo].[pozdoc] 
(
	[Tip] ASC,
	[Subunitate] ASC,
	[Data] ASC,
	[Numar] ASC
)
INCLUDE ( [Cantitate],
[Pret_de_stoc]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_313820230_5_2_18_3] ON [dbo].[pozdoc]([Data], [Tip], [Cod_intrare], [Numar])
go

CREATE STATISTICS [_dta_stat_313820230_3_4_1_5] ON [dbo].[pozdoc]([Numar], [Cod], [Subunitate], [Data])
go

CREATE STATISTICS [_dta_stat_313820230_33_2_18_5_6] ON [dbo].[pozdoc]([Tert], [Tip], [Cod_intrare], [Data], [Gestiune])
go

CREATE STATISTICS [_dta_stat_313820230_4_2_18_5_3] ON [dbo].[pozdoc]([Cod], [Tip], [Cod_intrare], [Data], [Numar])
go

CREATE STATISTICS [_dta_stat_313820230_1_2_18_5_3] ON [dbo].[pozdoc]([Subunitate], [Tip], [Cod_intrare], [Data], [Numar])
go

CREATE STATISTICS [_dta_stat_313820230_38_2_5_26_3] ON [dbo].[pozdoc]([Grupa], [Tip], [Data], [Numar_pozitie], [Numar])
go

CREATE STATISTICS [_dta_stat_313820230_6_2_18_5_26] ON [dbo].[pozdoc]([Gestiune], [Tip], [Cod_intrare], [Data], [Numar_pozitie])
go

CREATE STATISTICS [_dta_stat_313820230_27_2_18_5_6_1] ON [dbo].[pozdoc]([Loc_de_munca], [Tip], [Cod_intrare], [Data], [Gestiune], [Subunitate])
go

CREATE STATISTICS [_dta_stat_313820230_4_1_5_3_6_18] ON [dbo].[pozdoc]([Cod], [Subunitate], [Data], [Numar], [Gestiune], [Cod_intrare])
go

CREATE STATISTICS [_dta_stat_313820230_1_33_2_18_5_6] ON [dbo].[pozdoc]([Subunitate], [Tert], [Tip], [Cod_intrare], [Data], [Gestiune])
go

CREATE STATISTICS [_dta_stat_313820230_6_2_18_5_3_1] ON [dbo].[pozdoc]([Gestiune], [Tip], [Cod_intrare], [Data], [Numar], [Subunitate])
go

CREATE STATISTICS [_dta_stat_313820230_6_18_4_2_5_26] ON [dbo].[pozdoc]([Gestiune], [Cod_intrare], [Cod], [Tip], [Data], [Numar_pozitie])
go

CREATE STATISTICS [_dta_stat_313820230_4_2_18_5_26_3_6] ON [dbo].[pozdoc]([Cod], [Tip], [Cod_intrare], [Data], [Numar_pozitie], [Numar], [Gestiune])
go

CREATE STATISTICS [_dta_stat_313820230_2_18_5_26_3_6_1] ON [dbo].[pozdoc]([Tip], [Cod_intrare], [Data], [Numar_pozitie], [Numar], [Gestiune], [Subunitate])
go

CREATE STATISTICS [_dta_stat_313820230_26_4_1_5_3_2_6] ON [dbo].[pozdoc]([Numar_pozitie], [Cod], [Subunitate], [Data], [Numar], [Tip], [Gestiune])
go

CREATE STATISTICS [_dta_stat_313820230_35_2_5_26_3_1_4_6] ON [dbo].[pozdoc]([Gestiune_primitoare], [Tip], [Data], [Numar_pozitie], [Numar], [Subunitate], [Cod], [Gestiune])
go

CREATE STATISTICS [_dta_stat_313820230_4_1_5_6_18_2_33_46_27] ON [dbo].[pozdoc]([Cod], [Subunitate], [Data], [Gestiune], [Cod_intrare], [Tip], [Tert], [Accize_cumparare], [Loc_de_munca])
go

CREATE STATISTICS [_dta_stat_313820230_2_5_26_3_1_38_4_6_18] ON [dbo].[pozdoc]([Tip], [Data], [Numar_pozitie], [Numar], [Subunitate], [Grupa], [Cod], [Gestiune], [Cod_intrare])
go

CREATE STATISTICS [_dta_stat_313820230_1_5_3_2_26_35_38_4_6] ON [dbo].[pozdoc]([Subunitate], [Data], [Numar], [Tip], [Numar_pozitie], [Gestiune_primitoare], [Grupa], [Cod], [Gestiune])
go

CREATE STATISTICS [_dta_stat_313820230_2_18_5_6_1_4_33_3_26_35] ON [dbo].[pozdoc]([Tip], [Cod_intrare], [Data], [Gestiune], [Subunitate], [Cod], [Tert], [Numar], [Numar_pozitie], [Gestiune_primitoare])
go

CREATE STATISTICS [_dta_stat_313820230_4_46_2_18_5_6_1_3_26_35_38] ON [dbo].[pozdoc]([Cod], [Accize_cumparare], [Tip], [Cod_intrare], [Data], [Gestiune], [Subunitate], [Numar], [Numar_pozitie], [Gestiune_primitoare], [Grupa])
go

CREATE STATISTICS [_dta_stat_313820230_2_18_5_6_1_4_27_3_26_35_38_33] ON [dbo].[pozdoc]([Tip], [Cod_intrare], [Data], [Gestiune], [Subunitate], [Cod], [Loc_de_munca], [Numar], [Numar_pozitie], [Gestiune_primitoare], [Grupa], [Tert])
go

CREATE STATISTICS [_dta_stat_313820230_6_18_4_2_5_3_1_26_35_38_33_46_27] ON [dbo].[pozdoc]([Gestiune], [Cod_intrare], [Cod], [Tip], [Data], [Numar], [Subunitate], [Numar_pozitie], [Gestiune_primitoare], [Grupa], [Tert], [Accize_cumparare], [Loc_de_munca])
go

CREATE NONCLUSTERED INDEX [_dta_index_preturi_8_905770284__K1] ON [dbo].[preturi] 
(
	[Cod_produs] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [_dta_index_nomencl_8_188787980__K1_K10_3] ON [dbo].[nomencl] 
(
	[Cod] ASC,
	[Grupa] ASC
)
INCLUDE ( [Denumire]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_188787980_10_1] ON [dbo].[nomencl]([Grupa], [Cod])
go

CREATE NONCLUSTERED INDEX [_dta_index_CalStd_8_162099618__K2_K1] ON [dbo].[CalStd] 
(
	[Data_lunii] ASC,
	[Data] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_1620252877_2_3] ON [dbo].[proprietati]([Cod], [Cod_proprietate])
go

