﻿CREATE TABLE [dbo].[yso_syssd] (
    [Host_id]             CHAR (10)      NOT NULL,
    [Host_name]           NVARCHAR (128) NULL,
    [Aplicatia]           CHAR (30)      NULL,
    [Data_stergerii]      DATETIME       NOT NULL,
    [Stergator]           CHAR (10)      NULL,
    [Subunitate]          CHAR (9)       NOT NULL,
    [Tip]                 CHAR (2)       NOT NULL,
    [Numar]               CHAR (8)       NOT NULL,
    [Cod_gestiune]        CHAR (9)       NOT NULL,
    [Data]                DATETIME       NOT NULL,
    [Cod_tert]            CHAR (13)      NOT NULL,
    [Factura]             CHAR (20)      NOT NULL,
    [Contractul]          CHAR (20)      NOT NULL,
    [Loc_munca]           CHAR (9)       NOT NULL,
    [Comanda]             CHAR (40)      NOT NULL,
    [Gestiune_primitoare] CHAR (13)      NOT NULL,
    [Valuta]              CHAR (3)       NOT NULL,
    [Curs]                FLOAT (53)     NOT NULL,
    [Valoare]             FLOAT (53)     NOT NULL,
    [Tva_11]              FLOAT (53)     NOT NULL,
    [Tva_22]              FLOAT (53)     NOT NULL,
    [Valoare_valuta]      FLOAT (53)     NOT NULL,
    [Cota_TVA]            REAL           NOT NULL,
    [Discount_p]          REAL           NOT NULL,
    [Discount_suma]       FLOAT (53)     NOT NULL,
    [Pro_forma]           BINARY (1)     NOT NULL,
    [Tip_miscare]         CHAR (1)       NOT NULL,
    [Numar_DVI]           CHAR (30)      NOT NULL,
    [Cont_factura]        CHAR (13)      NOT NULL,
    [Data_facturii]       DATETIME       NOT NULL,
    [Data_scadentei]      DATETIME       NOT NULL,
    [Jurnal]              CHAR (3)       NOT NULL,
    [Numar_pozitii]       INT            NOT NULL,
    [Stare]               SMALLINT       NOT NULL,
    [detalii]             XML            NULL
);

