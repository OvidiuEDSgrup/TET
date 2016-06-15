CREATE TABLE [dbo].[stocuri] (
    [Subunitate]                CHAR (9)     NOT NULL,
    [Tip_gestiune]              CHAR (1)     NOT NULL,
    [Cod_gestiune]              CHAR (20)    NOT NULL,
    [Cod]                       CHAR (20)    NOT NULL,
    [Data]                      DATETIME     NOT NULL,
    [Cod_intrare]               CHAR (13)    NOT NULL,
    [Pret]                      FLOAT (53)   NOT NULL,
    [Stoc_initial]              FLOAT (53)   NOT NULL,
    [Intrari]                   FLOAT (53)   NOT NULL,
    [Iesiri]                    FLOAT (53)   NOT NULL,
    [Data_ultimei_iesiri]       DATETIME     NOT NULL,
    [Stoc]                      FLOAT (53)   NOT NULL,
    [Cont]                      VARCHAR (20) NULL,
    [Data_expirarii]            DATETIME     NOT NULL,
    [Stoc_ce_se_calculeaza]     FLOAT (53)   NOT NULL,
    [Are_documente_in_perioada] BIT          NOT NULL,
    [TVA_neexigibil]            REAL         NOT NULL,
    [Pret_cu_amanuntul]         FLOAT (53)   NOT NULL,
    [Locatie]                   CHAR (30)    NOT NULL,
    [Pret_vanzare]              FLOAT (53)   NOT NULL,
    [Loc_de_munca]              CHAR (9)     NOT NULL,
    [Comanda]                   CHAR (40)    NOT NULL,
    [Contract]                  CHAR (20)    NOT NULL,
    [Furnizor]                  CHAR (13)    NOT NULL,
    [Lot]                       CHAR (20)    NOT NULL,
    [Stoc_initial_UM2]          FLOAT (53)   NOT NULL,
    [Intrari_UM2]               FLOAT (53)   NOT NULL,
    [Iesiri_UM2]                FLOAT (53)   NOT NULL,
    [Stoc_UM2]                  FLOAT (53)   NOT NULL,
    [Stoc2_ce_se_calculeaza]    FLOAT (53)   NOT NULL,
    [Val1]                      FLOAT (53)   NOT NULL,
    [Alfa1]                     CHAR (30)    NOT NULL,
    [Data1]                     DATETIME     NOT NULL,
    [idIntrareFirma]            INT          NULL,
    [idIntrare]                 INT          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[stocuri]([Subunitate] ASC, [Tip_gestiune] ASC, [Cod_gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Cod_Stoc]
    ON [dbo].[stocuri]([Subunitate] ASC, [Cod] ASC, [Stoc] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_preturi]
    ON [dbo].[stocuri]([Subunitate] ASC, [Cod] ASC, [Pret] ASC);


GO
CREATE NONCLUSTERED INDEX [Locatie]
    ON [dbo].[stocuri]([Locatie] ASC, [Stoc] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [FIFO_dataexp]
    ON [dbo].[stocuri]([Subunitate] ASC, [Tip_gestiune] ASC, [Cod_gestiune] ASC, [Cod] ASC, [Data_expirarii] ASC, [Cod_intrare] ASC);


GO
CREATE NONCLUSTERED INDEX [EDS]
    ON [dbo].[stocuri]([Subunitate] ASC, [Cod_gestiune] ASC, [Cod] ASC, [Stoc] ASC, [Comanda] ASC);

