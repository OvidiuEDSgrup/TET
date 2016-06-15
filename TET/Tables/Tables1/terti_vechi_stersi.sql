﻿CREATE TABLE [dbo].[terti_vechi_stersi] (
    [Subunitate]               CHAR (9)   NOT NULL,
    [Tert]                     CHAR (13)  NOT NULL,
    [Denumire]                 CHAR (80)  NOT NULL,
    [Cod_fiscal]               CHAR (16)  NOT NULL,
    [Localitate]               CHAR (35)  NOT NULL,
    [Judet]                    CHAR (20)  NOT NULL,
    [Adresa]                   CHAR (60)  NOT NULL,
    [Telefon_fax]              CHAR (20)  NOT NULL,
    [Banca]                    CHAR (20)  NOT NULL,
    [Cont_in_banca]            CHAR (35)  NOT NULL,
    [Tert_extern]              BIT        NOT NULL,
    [Grupa]                    CHAR (3)   NOT NULL,
    [Cont_ca_furnizor]         CHAR (13)  NOT NULL,
    [Cont_ca_beneficiar]       CHAR (13)  NOT NULL,
    [Sold_ca_furnizor]         FLOAT (53) NOT NULL,
    [Sold_ca_beneficiar]       FLOAT (53) NOT NULL,
    [Sold_maxim_ca_beneficiar] FLOAT (53) NOT NULL,
    [Disccount_acordat]        REAL       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[terti_vechi_stersi]([Subunitate] ASC, [Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[terti_vechi_stersi]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_fiscal]
    ON [dbo].[terti_vechi_stersi]([Cod_fiscal] ASC);

