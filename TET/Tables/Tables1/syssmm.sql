﻿CREATE TABLE [dbo].[syssmm] (
    [Host_id]                 CHAR (10)    NOT NULL,
    [Host_name]               CHAR (30)    NOT NULL,
    [Aplicatia]               CHAR (30)    NOT NULL,
    [Data_stergerii]          DATETIME     NOT NULL,
    [Stergator]               CHAR (10)    NOT NULL,
    [Subunitate]              CHAR (9)     NOT NULL,
    [Data_lunii_de_miscare]   DATETIME     NOT NULL,
    [Numar_de_inventar]       CHAR (13)    NOT NULL,
    [Tip_miscare]             CHAR (3)     NOT NULL,
    [Numar_document]          CHAR (8)     NOT NULL,
    [Data_miscarii]           DATETIME     NOT NULL,
    [Tert]                    CHAR (13)    NOT NULL,
    [Factura]                 CHAR (20)    NOT NULL,
    [Pret]                    FLOAT (53)   NOT NULL,
    [TVA]                     FLOAT (53)   NOT NULL,
    [Cont_corespondent]       VARCHAR (20) NULL,
    [Loc_de_munca_primitor]   VARCHAR (20) NULL,
    [Gestiune_primitoare]     VARCHAR (20) NULL,
    [Diferenta_de_valoare]    FLOAT (53)   NOT NULL,
    [Data_sfarsit_conservare] DATETIME     NOT NULL,
    [Subunitate_primitoare]   CHAR (40)    NOT NULL,
    [Procent_inchiriere]      REAL         NOT NULL
) ON [SYSS];
