CREATE TABLE [dbo].[_pv] (
    [Subunitate]          CHAR (9)   NOT NULL,
    [Tip]                 CHAR (2)   NOT NULL,
    [Numar]               CHAR (8)   NOT NULL,
    [Cod_gestiune]        CHAR (9)   NOT NULL,
    [Data]                DATETIME   NOT NULL,
    [Cod_tert]            CHAR (13)  NOT NULL,
    [Factura]             CHAR (20)  NOT NULL,
    [Contractul]          CHAR (20)  NOT NULL,
    [Loc_munca]           CHAR (9)   NOT NULL,
    [Comanda]             CHAR (13)  NOT NULL,
    [Gestiune_primitoare] CHAR (9)   NOT NULL,
    [Valuta]              CHAR (3)   NOT NULL,
    [Curs]                FLOAT (53) NOT NULL,
    [Valoare]             FLOAT (53) NOT NULL,
    [Tva_11]              FLOAT (53) NOT NULL,
    [Tva_22]              FLOAT (53) NOT NULL,
    [Valoare_valuta]      FLOAT (53) NOT NULL,
    [Cota_TVA]            SMALLINT   NOT NULL,
    [Discount_p]          REAL       NOT NULL,
    [Discount_suma]       FLOAT (53) NOT NULL,
    [Pro_forma]           BINARY (1) NOT NULL,
    [Tip_miscare]         CHAR (1)   NOT NULL,
    [Numar_DVI]           CHAR (13)  NOT NULL,
    [Cont_factura]        CHAR (13)  NOT NULL,
    [Data_facturii]       DATETIME   NOT NULL,
    [Data_scadentei]      DATETIME   NOT NULL,
    [Jurnal]              CHAR (3)   NOT NULL,
    [Numar_pozitii]       INT        NOT NULL,
    [Stare]               SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[_pv]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Actualizare]
    ON [dbo].[_pv]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [Facturare]
    ON [dbo].[_pv]([Subunitate] ASC, [Cod_tert] ASC, [Factura] ASC, [Tip] ASC, [Pro_forma] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar]
    ON [dbo].[_pv]([Numar] ASC);

