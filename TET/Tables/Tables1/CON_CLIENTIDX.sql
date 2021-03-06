﻿CREATE TABLE [dbo].[CON_CLIENTIDX] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Tip]                CHAR (2)   NOT NULL,
    [Contract]           CHAR (20)  NOT NULL,
    [Tert]               CHAR (13)  NOT NULL,
    [Punct_livrare]      CHAR (13)  NOT NULL,
    [Data]               DATETIME   NOT NULL,
    [Stare]              CHAR (1)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Gestiune]           CHAR (9)   NOT NULL,
    [Termen]             DATETIME   NOT NULL,
    [Scadenta]           SMALLINT   NOT NULL,
    [Discount]           REAL       NOT NULL,
    [Valuta]             CHAR (3)   NOT NULL,
    [Curs]               FLOAT (53) NOT NULL,
    [Mod_plata]          CHAR (1)   NOT NULL,
    [Mod_ambalare]       CHAR (1)   NOT NULL,
    [Factura]            CHAR (20)  NOT NULL,
    [Total_contractat]   FLOAT (53) NOT NULL,
    [Total_TVA]          FLOAT (53) NOT NULL,
    [Contract_coresp]    CHAR (20)  NOT NULL,
    [Mod_penalizare]     CHAR (13)  NOT NULL,
    [Procent_penalizare] REAL       NOT NULL,
    [Procent_avans]      REAL       NOT NULL,
    [Avans]              FLOAT (53) NOT NULL,
    [Nr_rate]            SMALLINT   NOT NULL,
    [Val_reziduala]      FLOAT (53) NOT NULL,
    [Sold_initial]       FLOAT (53) NOT NULL,
    [Cod_dobanda]        CHAR (20)  NOT NULL,
    [Dobanda]            REAL       NOT NULL,
    [Incasat]            FLOAT (53) NOT NULL,
    [Responsabil]        CHAR (20)  NOT NULL,
    [Responsabil_tert]   CHAR (20)  NOT NULL,
    [Explicatii]         CHAR (50)  NOT NULL,
    [Data_rezilierii]    DATETIME   NOT NULL
);

