﻿CREATE TABLE [dbo].[CLIENTI_PUTINI] (
    [CLIENT]         VARCHAR (200) NULL,
    [Subunitate]     INT           IDENTITY (1, 1) NOT NULL,
    [tip]            VARCHAR (50)  NULL,
    [contract]       VARCHAR (50)  NULL,
    [cod_fiscal]     VARCHAR (50)  NULL,
    [Data]           VARCHAR (50)  NULL,
    [Stare]          VARCHAR (50)  NULL,
    [Loc_de_munca]   VARCHAR (100) NULL,
    [gestiunea]      VARCHAR (50)  NULL,
    [termen_livrare] VARCHAR (50)  NULL,
    [termen_plata]   VARCHAR (50)  NULL,
    [tp_propus]      VARCHAR (50)  NULL,
    [scadenta]       VARCHAR (50)  NULL,
    [moneda]         VARCHAR (50)  NULL,
    [target]         VARCHAR (50)  NULL,
    [limita credit]  VARCHAR (50)  NULL,
    [lc_propusa]     VARCHAR (50)  NULL,
    [sold_maxim]     VARCHAR (50)  NULL,
    [SIC_CODE]       VARCHAR (50)  NULL,
    [SIC_CODE_TYPE]  VARCHAR (50)  NULL,
    [TAX_REFERENCE]  VARCHAR (50)  NULL,
    [regiune]        VARCHAR (50)  NULL
);
