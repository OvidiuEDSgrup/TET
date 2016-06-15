﻿CREATE TABLE [dbo].[AGENTI_CLIENTI_FINAL_COMPLETAT_INFOTERT] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Identificator]  CHAR (5)   NOT NULL,
    [Descriere]      CHAR (30)  NOT NULL,
    [Loc_munca]      CHAR (9)   NOT NULL,
    [Pers_contact]   CHAR (20)  NOT NULL,
    [Nume_delegat]   CHAR (30)  NOT NULL,
    [Buletin]        CHAR (12)  NOT NULL,
    [Eliberat]       CHAR (30)  NOT NULL,
    [Mijloc_tp]      CHAR (20)  NOT NULL,
    [Adresa2]        CHAR (20)  NOT NULL,
    [Telefon_fax2]   CHAR (20)  NOT NULL,
    [e_mail]         CHAR (50)  NOT NULL,
    [Banca2]         CHAR (20)  NOT NULL,
    [Cont_in_banca2] CHAR (35)  NOT NULL,
    [Banca3]         CHAR (20)  NOT NULL,
    [Cont_in_banca3] CHAR (35)  NOT NULL,
    [Indicator]      BIT        NOT NULL,
    [Grupa13]        CHAR (13)  NOT NULL,
    [Sold_ben]       FLOAT (53) NOT NULL,
    [Discount]       REAL       NOT NULL,
    [Zile_inc]       SMALLINT   NOT NULL,
    [Observatii]     CHAR (30)  NOT NULL
);

