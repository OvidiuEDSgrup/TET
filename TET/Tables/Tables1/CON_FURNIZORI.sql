﻿CREATE TABLE [dbo].[CON_FURNIZORI] (
    [Subunitate]         BIGINT        NULL,
    [Tip]                VARCHAR (50)  NULL,
    [Contract]           VARCHAR (50)  NULL,
    [Tert]               VARCHAR (50)  NULL,
    [Punct_livrare]      VARCHAR (50)  NULL,
    [Data]               VARCHAR (50)  NULL,
    [Stare]              VARCHAR (50)  NULL,
    [Loc_de_munca]       VARCHAR (50)  NULL,
    [Gestiune]           VARCHAR (50)  NULL,
    [Termen]             VARCHAR (50)  NULL,
    [Scadenta]           VARCHAR (50)  NULL,
    [Discount]           VARCHAR (50)  NULL,
    [Valuta]             VARCHAR (50)  NULL,
    [Curs]               VARCHAR (50)  NULL,
    [Mod_plata]          VARCHAR (50)  NULL,
    [Mod_ambalare]       VARCHAR (50)  NULL,
    [Factura]            CHAR (20)     NOT NULL,
    [Total_contractat]   VARCHAR (50)  NULL,
    [Total_TVA]          VARCHAR (50)  NULL,
    [Contract_coresp]    VARCHAR (50)  NULL,
    [Mod_penalizare]     VARCHAR (50)  NULL,
    [Procent_penalizare] VARCHAR (50)  NULL,
    [Procent_avans]      VARCHAR (50)  NULL,
    [Avans]              VARCHAR (50)  NULL,
    [Nr_rate]            VARCHAR (50)  NULL,
    [Val_reziduala]      VARCHAR (50)  NULL,
    [Sold_initial]       VARCHAR (50)  NULL,
    [Cod_dobanda]        VARCHAR (50)  NULL,
    [Dobanda]            VARCHAR (50)  NULL,
    [Incasat]            VARCHAR (50)  NULL,
    [Responsabil]        VARCHAR (50)  NULL,
    [Responsabil_tert]   VARCHAR (50)  NULL,
    [Explicatii]         VARCHAR (50)  NULL,
    [Data_rezilierii]    VARCHAR (50)  NULL,
    [VALUTA PRET]        VARCHAR (50)  NULL,
    [furnizor]           VARCHAR (100) NULL
);
