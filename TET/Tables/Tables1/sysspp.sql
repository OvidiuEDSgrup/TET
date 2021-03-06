﻿CREATE TABLE [dbo].[sysspp] (
    [Host_id]                 CHAR (10)    NOT NULL,
    [Host_name]               CHAR (30)    NOT NULL,
    [Aplicatia]               CHAR (30)    NOT NULL,
    [Data_stergerii]          DATETIME     NOT NULL,
    [Stergator]               CHAR (10)    NOT NULL,
    [Data_operarii]           DATETIME     NOT NULL,
    [Ora_operarii]            CHAR (6)     NOT NULL,
    [Subunitate]              CHAR (9)     NOT NULL,
    [Cont]                    VARCHAR (20) NULL,
    [Data]                    DATETIME     NOT NULL,
    [Numar]                   CHAR (10)    NOT NULL,
    [Plata_incasare]          CHAR (2)     NOT NULL,
    [Tert]                    CHAR (13)    NOT NULL,
    [Factura]                 CHAR (20)    NOT NULL,
    [Cont_corespondent]       VARCHAR (20) NULL,
    [Suma]                    FLOAT (53)   NOT NULL,
    [Valuta]                  CHAR (3)     NOT NULL,
    [Curs]                    FLOAT (53)   NOT NULL,
    [Suma_valuta]             FLOAT (53)   NOT NULL,
    [Curs_la_valuta_facturii] FLOAT (53)   NOT NULL,
    [TVA11]                   FLOAT (53)   NOT NULL,
    [TVA22]                   FLOAT (53)   NOT NULL,
    [Explicatii]              CHAR (50)    NOT NULL,
    [Loc_de_munca]            CHAR (9)     NOT NULL,
    [Comanda]                 CHAR (40)    NOT NULL,
    [Utilizator]              CHAR (10)    NOT NULL,
    [Numar_pozitie]           INT          NOT NULL,
    [Cont_dif]                VARCHAR (20) NULL,
    [Suma_dif]                FLOAT (53)   NOT NULL,
    [Achit_fact]              FLOAT (53)   NOT NULL,
    [Jurnal]                  CHAR (3)     NOT NULL
) ON [SYSS];

