﻿CREATE TABLE [dbo].[FURNIZORI_PUTINIUNICI1] (
    [SUBUNITATE]               VARCHAR (1)  NOT NULL,
    [TERT]                     VARCHAR (22) NULL,
    [Denumire]                 CHAR (80)    NOT NULL,
    [Cod_fiscal]               CHAR (16)    NOT NULL,
    [Localitate]               CHAR (35)    NOT NULL,
    [Judet]                    CHAR (20)    NOT NULL,
    [Adresa]                   CHAR (60)    NOT NULL,
    [Telefon_fax]              CHAR (20)    NOT NULL,
    [Banca]                    CHAR (20)    NOT NULL,
    [Cont_in_banca]            CHAR (35)    NOT NULL,
    [Tert_extern]              BIT          NOT NULL,
    [Grupa]                    CHAR (3)     NOT NULL,
    [Cont_ca_furnizor]         CHAR (13)    NOT NULL,
    [Cont_ca_beneficiar]       CHAR (13)    NOT NULL,
    [Sold_ca_furnizor]         FLOAT (53)   NOT NULL,
    [Sold_ca_beneficiar]       FLOAT (53)   NOT NULL,
    [Sold_maxim_ca_beneficiar] FLOAT (53)   NOT NULL,
    [Disccount_acordat]        REAL         NOT NULL
);

