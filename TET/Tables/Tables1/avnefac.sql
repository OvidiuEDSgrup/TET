CREATE TABLE [dbo].[avnefac] (
    [Terminal]            VARCHAR (25) NULL,
    [Subunitate]          CHAR (9)     NOT NULL,
    [Tip]                 CHAR (2)     NOT NULL,
    [Numar]               CHAR (20)    NOT NULL,
    [Cod_gestiune]        CHAR (9)     NOT NULL,
    [Data]                DATETIME     NOT NULL,
    [Cod_tert]            CHAR (13)    NOT NULL,
    [Factura]             CHAR (20)    NOT NULL,
    [Contractul]          CHAR (20)    NOT NULL,
    [Data_facturii]       DATETIME     NOT NULL,
    [Loc_munca]           CHAR (9)     NOT NULL,
    [Comanda]             CHAR (13)    NOT NULL,
    [Gestiune_primitoare] CHAR (9)     NOT NULL,
    [Valuta]              CHAR (3)     NOT NULL,
    [Curs]                FLOAT (53)   NOT NULL,
    [Valoare]             FLOAT (53)   NOT NULL,
    [Valoare_valuta]      FLOAT (53)   NOT NULL,
    [Tva_11]              FLOAT (53)   NOT NULL,
    [Tva_22]              FLOAT (53)   NOT NULL,
    [Cont_beneficiar]     CHAR (13)    NOT NULL,
    [Discount]            REAL         NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[avnefac]([Terminal] ASC, [Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Cod_gestiune] ASC, [Data] ASC, [Contractul] ASC);

