use [tempdb]
go

CREATE NONCLUSTERED INDEX [_dta_index_doc_2_1867031486__K11D_K2D_1_3_4_5_6_7_8_9_10_13_14_15_16_17] ON [dbo].[doc] 
(
	[Data] DESC,
	[factura] DESC
)
INCLUDE ( denumire,
Tip,
Factura_stinga,
b_factura,
f_factura,
Numar,
Data_fact,
b_data_facturii,
f_data_facturii,
Valoare_valuta,
Valoare,
Tva_22,
Loc_munca,
Comanda) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_1867031486_3] ON [dbo].[doc]([Tip])
go

CREATE NONCLUSTERED INDEX [_dta_index_antetbonuri_2_1851031429__K4_K23_K2_K6_K7] ON [dbo].[antetbonuri] 
(
	[Data_bon] ASC,
	[yso_numar_in_pozdoc] ASC,
	[Chitanta] ASC,
	[Factura] ASC,
	[Data_facturii] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_1851031429_1] ON [dbo].[antetbonuri]([Casa_de_marcat])
go

CREATE STATISTICS [_dta_stat_1851031429_4_2_6] ON [dbo].[antetbonuri]([Data_bon], [Chitanta], [Factura])
go

CREATE STATISTICS [_dta_stat_1851031429_4_23_6_7] ON [dbo].[antetbonuri]([Data_bon], [yso_numar_in_pozdoc], [Factura], [Data_facturii])
go

CREATE STATISTICS [_dta_stat_1851031429_6_7_4_2_23] ON [dbo].[antetbonuri]([Factura], [Data_facturii], [Data_bon], [Chitanta], [yso_numar_in_pozdoc])
go

use [TET]
go

SET QUOTED_IDENTIFIER ON
go

SET ARITHABORT ON
go

SET CONCAT_NULL_YIELDS_NULL ON
go

SET ANSI_NULLS ON
go

SET ANSI_PADDING ON
go

SET ANSI_WARNINGS ON
go

SET NUMERIC_ROUNDABORT OFF
go

CREATE NONCLUSTERED INDEX [_dta_index_antetBonuri_7_1386032269__K2_K6_K4_K1_K5_K3_7_8_9_10_11_12_13_14_15_16_17_18_19_20_21_23] ON [dbo].[antetBonuri] 
(
	[Chitanta] ASC,
	[Factura] ASC,
	[Data_bon] ASC,
	[Casa_de_marcat] ASC,
	[Vinzator] ASC,
	[Numar_bon] ASC
)
INCLUDE ( [Data_facturii],
[Data_scadentei],
[Tert],
[Gestiune],
[Loc_de_munca],
[Persoana_de_contact],
[Punct_de_livrare],
[Categorie_de_pret],
[Contract],
[Comanda],
[Observatii],
[Explicatii],
[UID],
[Bon],
[IdAntetBon],
[UID_Card_Fidelizare]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE NONCLUSTERED INDEX [_dta_index_antetBonuri_7_1386032269__K6_K7_K2] ON [dbo].[antetBonuri] 
(
	[Factura] ASC,
	[Data_facturii] ASC,
	[Chitanta] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_1386032269_6_4] ON [dbo].[antetBonuri]([Factura], [Data_bon])
go

CREATE STATISTICS [_dta_stat_1386032269_1_6_4] ON [dbo].[antetBonuri]([Casa_de_marcat], [Factura], [Data_bon])
go

CREATE STATISTICS [_dta_stat_1386032269_5_6_4_2] ON [dbo].[antetBonuri]([Vinzator], [Factura], [Data_bon], [Chitanta])
go

CREATE STATISTICS [_dta_stat_1386032269_3_6_4_2_1] ON [dbo].[antetBonuri]([Numar_bon], [Factura], [Data_bon], [Chitanta], [Casa_de_marcat])
go

CREATE STATISTICS [_dta_stat_1386032269_4_1_5_3_6] ON [dbo].[antetBonuri]([Data_bon], [Casa_de_marcat], [Vinzator], [Numar_bon], [Factura])
go

CREATE NONCLUSTERED INDEX [_dta_index_doc_7_386854678__K1_K2_K5_K6_K3_K9_K7_10_14_16_17_25] ON [dbo].[doc] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Data] ASC,
	[Cod_tert] ASC,
	[Numar] ASC,
	[Loc_munca] ASC,
	[Factura] ASC
)
INCLUDE ( [Comanda],
[Valoare],
[Tva_22],
[Valoare_valuta],
[Data_facturii]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_386854678_6_5] ON [dbo].[doc]([Cod_tert], [Data])
go

CREATE STATISTICS [_dta_stat_386854678_1_7_5_6] ON [dbo].[doc]([Subunitate], [Factura], [Data], [Cod_tert])
go

CREATE STATISTICS [_dta_stat_386854678_3_5_1_6] ON [dbo].[doc]([Numar], [Data], [Subunitate], [Cod_tert])
go

CREATE STATISTICS [_dta_stat_386854678_9_5_1_6_2] ON [dbo].[doc]([Loc_munca], [Data], [Subunitate], [Cod_tert], [Tip])
go

CREATE STATISTICS [_dta_stat_386854678_2_5_3_6_9] ON [dbo].[doc]([Tip], [Data], [Numar], [Cod_tert], [Loc_munca])
go

CREATE STATISTICS [_dta_stat_386854678_5_2_3_1_6_9] ON [dbo].[doc]([Data], [Tip], [Numar], [Subunitate], [Cod_tert], [Loc_munca])
go

CREATE STATISTICS [_dta_stat_386854678_5_1_6_2_7_3_9] ON [dbo].[doc]([Data], [Subunitate], [Cod_tert], [Tip], [Factura], [Numar], [Loc_munca])
go

CREATE NONCLUSTERED INDEX [_dta_index_terti_7_176120514__K1_K2_3] ON [dbo].[terti] 
(
	[Subunitate] ASC,
	[Tert] ASC
)
INCLUDE ( [Denumire]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_181575685_1_2_6] ON [dbo].[conturi]([Subunitate], [Cont], [Are_analitice])
go

CREATE STATISTICS [_dta_stat_329820287_1_7_6] ON [dbo].[pozadoc]([Subunitate], [Factura_dreapta], [Factura_stinga])
go

