﻿CREATE TABLE [dbo].[NOMENCL_CONFIG_PACHETE] (
    [Cod]                    CHAR (20)  NOT NULL,
    [Tip]                    CHAR (1)   NOT NULL,
    [Denumire]               CHAR (150) NOT NULL,
    [UM]                     CHAR (3)   NOT NULL,
    [UM_1]                   CHAR (3)   NOT NULL,
    [Coeficient_conversie_1] FLOAT (53) NOT NULL,
    [UM_2]                   CHAR (20)  NOT NULL,
    [Coeficient_conversie_2] FLOAT (53) NOT NULL,
    [Cont]                   CHAR (13)  NOT NULL,
    [Grupa]                  CHAR (13)  NOT NULL,
    [Valuta]                 CHAR (3)   NOT NULL,
    [Pret_in_valuta]         FLOAT (53) NOT NULL,
    [Pret_stoc]              FLOAT (53) NOT NULL,
    [Pret_vanzare]           FLOAT (53) NOT NULL,
    [Pret_cu_amanuntul]      FLOAT (53) NOT NULL,
    [Cota_TVA]               REAL       NOT NULL,
    [Stoc_limita]            FLOAT (53) NOT NULL,
    [Stoc]                   FLOAT (53) NOT NULL,
    [Greutate_specifica]     FLOAT (53) NOT NULL,
    [Furnizor]               CHAR (13)  NOT NULL,
    [Loc_de_munca]           CHAR (150) NOT NULL,
    [Gestiune]               CHAR (13)  NOT NULL,
    [Categorie]              SMALLINT   NOT NULL,
    [Tip_echipament]         CHAR (21)  NOT NULL
);
