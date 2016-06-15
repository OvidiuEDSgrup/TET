CREATE TABLE [dbo].[antetBonuri] (
    [Casa_de_marcat]      SMALLINT       NOT NULL,
    [Chitanta]            INT            NULL,
    [Numar_bon]           INT            NOT NULL,
    [Data_bon]            DATETIME       NOT NULL,
    [Vinzator]            VARCHAR (10)   NOT NULL,
    [Factura]             VARCHAR (20)   NULL,
    [Data_facturii]       DATETIME       NULL,
    [Data_scadentei]      DATETIME       NULL,
    [Tert]                VARCHAR (50)   NULL,
    [Gestiune]            VARCHAR (50)   NULL,
    [Loc_de_munca]        VARCHAR (50)   NULL,
    [Persoana_de_contact] VARCHAR (50)   NULL,
    [Punct_de_livrare]    VARCHAR (50)   NULL,
    [Categorie_de_pret]   SMALLINT       NULL,
    [Contract]            VARCHAR (8)    NULL,
    [Comanda]             VARCHAR (13)   NULL,
    [Observatii]          VARCHAR (2000) NULL,
    [Explicatii]          VARCHAR (500)  NULL,
    [UID]                 VARCHAR (36)   NULL,
    [Bon]                 XML            NULL,
    [IdAntetBon]          INT            IDENTITY (1, 1) NOT NULL,
    [UID_Card_Fidelizare] AS             ([dbo].[f_antetBonuri_UidCardFidelizareDinXml]([bon])) PERSISTED,
    [yso_numar_in_pozdoc] AS             ([dbo].[yso_wfIaValAtribXml]([Bon],'numar_in_pozdoc')) PERSISTED
);


GO
CREATE UNIQUE CLUSTERED INDEX [Numar_bon_Tip]
    ON [dbo].[antetBonuri]([Data_bon] ASC, [Casa_de_marcat] ASC, [Vinzator] ASC, [Numar_bon] ASC);


GO
CREATE NONCLUSTERED INDEX [Tert]
    ON [dbo].[antetBonuri]([Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_dupaFactura]
    ON [dbo].[antetBonuri]([Factura] ASC, [Data_facturii] ASC)
    INCLUDE([IdAntetBon], [Chitanta], [Tert], [Casa_de_marcat], [Data_bon], [Numar_bon]);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_idAntetBon]
    ON [dbo].[antetBonuri]([IdAntetBon] ASC)
    INCLUDE([Data_bon], [Casa_de_marcat], [Vinzator], [Numar_bon]);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Uid]
    ON [dbo].[antetBonuri]([UID] ASC, [Casa_de_marcat] ASC, [Data_bon] ASC, [Numar_bon] ASC);


GO
CREATE NONCLUSTERED INDEX [factura_datafacturii]
    ON [dbo].[antetBonuri]([Factura] ASC, [Data_facturii] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_yso_numar_in_pozdoc]
    ON [dbo].[antetBonuri]([Chitanta] ASC, [Data_bon] ASC, [yso_numar_in_pozdoc] ASC);


GO
CREATE STATISTICS [_dta_stat_1386032269_6_4]
    ON [dbo].[antetBonuri]([Factura], [Data_bon]);


GO
CREATE STATISTICS [_dta_stat_1386032269_1_6_4]
    ON [dbo].[antetBonuri]([Casa_de_marcat], [Factura], [Data_bon]);


GO
CREATE STATISTICS [_dta_stat_1386032269_5_6_4_2]
    ON [dbo].[antetBonuri]([Vinzator], [Factura], [Data_bon], [Chitanta]);


GO
CREATE STATISTICS [_dta_stat_1386032269_3_6_4_2_1]
    ON [dbo].[antetBonuri]([Numar_bon], [Factura], [Data_bon], [Chitanta], [Casa_de_marcat]);


GO
CREATE STATISTICS [_dta_stat_1386032269_4_1_5_3_6]
    ON [dbo].[antetBonuri]([Data_bon], [Casa_de_marcat], [Vinzator], [Numar_bon], [Factura]);

