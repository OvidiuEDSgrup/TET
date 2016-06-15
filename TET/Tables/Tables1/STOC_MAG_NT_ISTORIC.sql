﻿CREATE TABLE [dbo].[STOC_MAG_NT_ISTORIC] (
    [Subunitate]        CHAR (9)   NOT NULL,
    [Data_lunii]        DATETIME   NOT NULL,
    [Tip_gestiune]      CHAR (1)   NOT NULL,
    [Cod_gestiune]      CHAR (20)  NOT NULL,
    [Cod]               CHAR (20)  NOT NULL,
    [Data]              DATETIME   NOT NULL,
    [Cod_intrare]       CHAR (20)  NOT NULL,
    [Pret]              FLOAT (53) NOT NULL,
    [TVA_neexigibil]    REAL       NOT NULL,
    [Pret_cu_amanuntul] FLOAT (53) NOT NULL,
    [Stoc]              FLOAT (53) NOT NULL,
    [Cont]              CHAR (13)  NOT NULL,
    [Locatie]           CHAR (30)  NOT NULL,
    [Data_expirarii]    DATETIME   NOT NULL,
    [Pret_vanzare]      FLOAT (53) NOT NULL,
    [Loc_de_munca]      CHAR (9)   NOT NULL,
    [Comanda]           CHAR (40)  NOT NULL,
    [Contract]          CHAR (20)  NOT NULL,
    [Furnizor]          CHAR (13)  NOT NULL,
    [Lot]               CHAR (20)  NOT NULL,
    [Stoc_UM2]          FLOAT (53) NOT NULL,
    [Val1]              FLOAT (53) NOT NULL,
    [Alfa1]             CHAR (30)  NOT NULL,
    [Data1]             DATETIME   NOT NULL
);

