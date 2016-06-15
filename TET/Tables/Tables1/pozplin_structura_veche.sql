﻿CREATE TABLE [dbo].[pozplin_structura_veche] (
    [Subunitate]              CHAR (9)     NOT NULL,
    [Cont]                    CHAR (13)    NOT NULL,
    [Data]                    DATETIME     NOT NULL,
    [Numar]                   CHAR (10)    NOT NULL,
    [Plata_incasare]          CHAR (2)     NOT NULL,
    [Tert]                    CHAR (13)    NOT NULL,
    [Factura]                 CHAR (20)    NOT NULL,
    [Cont_corespondent]       CHAR (13)    NOT NULL,
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
    [Data_operarii]           DATETIME     NOT NULL,
    [Ora_operarii]            CHAR (6)     NOT NULL,
    [Numar_pozitie]           INT          NOT NULL,
    [Cont_dif]                CHAR (13)    NOT NULL,
    [Suma_dif]                FLOAT (53)   NOT NULL,
    [Achit_fact]              FLOAT (53)   NOT NULL,
    [Jurnal]                  CHAR (3)     NOT NULL,
    [detalii]                 XML          NULL,
    [tip_tva]                 INT          NULL,
    [marca]                   VARCHAR (20) NULL,
    [decont]                  VARCHAR (20) NULL,
    [efect]                   VARCHAR (20) NULL,
    [idPozPlin]               INT          IDENTITY (1, 1) NOT NULL
);
