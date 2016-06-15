CREATE TABLE [dbo].[_pozpv] (
    [Subunitate]            CHAR (9)   NOT NULL,
    [Tip]                   CHAR (2)   NOT NULL,
    [Numar]                 CHAR (8)   NOT NULL,
    [Cod]                   CHAR (20)  NOT NULL,
    [Data]                  DATETIME   NOT NULL,
    [Gestiune]              CHAR (9)   NOT NULL,
    [Cantitate]             FLOAT (53) NOT NULL,
    [Pret_valuta]           FLOAT (53) NOT NULL,
    [Pret_de_stoc]          FLOAT (53) NOT NULL,
    [Adaos]                 REAL       NOT NULL,
    [Pret_vanzare]          FLOAT (53) NOT NULL,
    [Pret_cu_amanuntul]     FLOAT (53) NOT NULL,
    [TVA_deductibil]        FLOAT (53) NOT NULL,
    [Cota_TVA]              REAL       NOT NULL,
    [Utilizator]            CHAR (10)  NOT NULL,
    [Data_operarii]         DATETIME   NOT NULL,
    [Ora_operarii]          CHAR (6)   NOT NULL,
    [Cod_intrare]           CHAR (13)  NOT NULL,
    [Cont_de_stoc]          CHAR (13)  NOT NULL,
    [Cont_corespondent]     CHAR (13)  NOT NULL,
    [TVA_neexigibil]        REAL       NOT NULL,
    [Pret_amanunt_predator] FLOAT (53) NOT NULL,
    [Tip_miscare]           CHAR (1)   NOT NULL,
    [Locatie]               CHAR (13)  NOT NULL,
    [Data_expirarii]        DATETIME   NOT NULL,
    [Numar_pozitie]         INT        NOT NULL,
    [Loc_de_munca]          CHAR (9)   NOT NULL,
    [Comanda]               CHAR (13)  NOT NULL,
    [Barcod]                CHAR (13)  NOT NULL,
    [Cont_intermediar]      CHAR (13)  NOT NULL,
    [Cont_venituri]         CHAR (13)  NOT NULL,
    [Discount]              REAL       NOT NULL,
    [Tert]                  CHAR (13)  NOT NULL,
    [Factura]               CHAR (20)  NOT NULL,
    [Gestiune_primitoare]   CHAR (9)   NOT NULL,
    [Numar_DVI]             CHAR (13)  NOT NULL,
    [Stare]                 SMALLINT   NOT NULL,
    [Grupa]                 CHAR (13)  NOT NULL,
    [Cont_factura]          CHAR (13)  NOT NULL,
    [Valuta]                CHAR (3)   NOT NULL,
    [Curs]                  FLOAT (53) NOT NULL,
    [Data_facturii]         DATETIME   NOT NULL,
    [Data_scadentei]        DATETIME   NOT NULL,
    [Procent_vama]          REAL       NOT NULL,
    [Suprataxe_vama]        FLOAT (53) NOT NULL,
    [Accize_cumparare]      FLOAT (53) NOT NULL,
    [Accize_datorate]       FLOAT (53) NOT NULL,
    [Contract]              CHAR (20)  NOT NULL,
    [Jurnal]                CHAR (3)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pentru_culegere]
    ON [dbo].[_pozpv]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[_pozpv]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Numar_pozitie] ASC, [Pret_vanzare] ASC);


GO
CREATE NONCLUSTERED INDEX [Balanta]
    ON [dbo].[_pozpv]([Subunitate] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Data] ASC, [Tip_miscare] ASC);


GO
CREATE NONCLUSTERED INDEX [Terti]
    ON [dbo].[_pozpv]([Subunitate] ASC, [Tip] ASC, [Tert] ASC, [Factura] ASC);

