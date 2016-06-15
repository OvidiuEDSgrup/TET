CREATE TABLE [dbo].[stocpm] (
    [Subunitate]                CHAR (9)   NOT NULL,
    [Tip_gestiune]              CHAR (1)   NOT NULL,
    [Cod_gestiune]              CHAR (9)   NOT NULL,
    [Cod]                       CHAR (20)  NOT NULL,
    [Data]                      DATETIME   NOT NULL,
    [Cod_intrare]               CHAR (13)  NOT NULL,
    [Pret]                      FLOAT (53) NOT NULL,
    [Stoc_initial]              FLOAT (53) NOT NULL,
    [Intrari]                   FLOAT (53) NOT NULL,
    [Iesiri]                    FLOAT (53) NOT NULL,
    [Data_ultimei_iesiri]       DATETIME   NOT NULL,
    [Stoc]                      FLOAT (53) NOT NULL,
    [Cont]                      CHAR (13)  NOT NULL,
    [Data_expirarii]            DATETIME   NOT NULL,
    [Stoc_ce_se_calculeaza]     FLOAT (53) NOT NULL,
    [Are_documente_in_perioada] BIT        NOT NULL,
    [TVA_neexigibil]            REAL       NOT NULL,
    [Pret_cu_amanuntul]         FLOAT (53) NOT NULL,
    [Locatie]                   CHAR (13)  NOT NULL,
    [Pret_vanzare]              FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic_stpm]
    ON [dbo].[stocpm]([Subunitate] ASC, [Tip_gestiune] ASC, [Cod_gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Cod_stpm]
    ON [dbo].[stocpm]([Subunitate] ASC, [Cod] ASC);

