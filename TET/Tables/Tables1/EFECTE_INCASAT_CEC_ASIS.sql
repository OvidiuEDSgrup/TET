﻿CREATE TABLE [dbo].[EFECTE_INCASAT_CEC_ASIS] (
    [Subunitate]      CHAR (9)   NOT NULL,
    [Tip]             CHAR (1)   NOT NULL,
    [Tert]            CHAR (13)  NOT NULL,
    [Nr_efect]        CHAR (8)   NOT NULL,
    [Cont]            CHAR (13)  NOT NULL,
    [Data]            DATETIME   NOT NULL,
    [Data_scadentei]  DATETIME   NOT NULL,
    [Valoare]         FLOAT (53) NOT NULL,
    [Valuta]          CHAR (3)   NOT NULL,
    [Curs]            FLOAT (53) NOT NULL,
    [Valoare_valuta]  FLOAT (53) NOT NULL,
    [Decontat]        FLOAT (53) NOT NULL,
    [Sold]            FLOAT (53) NOT NULL,
    [Decontat_valuta] FLOAT (53) NOT NULL,
    [Sold_valuta]     FLOAT (53) NOT NULL,
    [Loc_de_munca]    CHAR (9)   NOT NULL,
    [Comanda]         CHAR (40)  NOT NULL,
    [Data_decontarii] DATETIME   NOT NULL,
    [Explicatii]      CHAR (30)  NOT NULL
);

