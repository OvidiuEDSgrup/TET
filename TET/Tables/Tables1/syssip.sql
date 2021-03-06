﻿CREATE TABLE [dbo].[syssip] (
    [Host_id]                 CHAR (10)    NOT NULL,
    [Host_name]               CHAR (30)    NOT NULL,
    [Aplicatia]               CHAR (30)    NOT NULL,
    [Data_stergerii]          DATETIME     NOT NULL,
    [Stergator]               CHAR (10)    NOT NULL,
    [Tip_act]                 CHAR (1)     NOT NULL,
    [Marca]                   CHAR (6)     NOT NULL,
    [Permis_auto_categoria]   CHAR (10)    NOT NULL,
    [Limbi_straine]           CHAR (30)    NOT NULL,
    [Nationalitatea]          CHAR (10)    NOT NULL,
    [Cetatenia]               CHAR (10)    NOT NULL,
    [Starea_civila]           CHAR (1)     NOT NULL,
    [Marca_sot_sotie]         CHAR (6)     NOT NULL,
    [Nume_sot_sotie]          CHAR (30)    NOT NULL,
    [Religia]                 VARCHAR (25) NULL,
    [Evidenta_militara]       CHAR (1)     NOT NULL,
    [Telefon]                 CHAR (15)    NOT NULL,
    [Email]                   CHAR (50)    NOT NULL,
    [Observatii]              CHAR (100)   NOT NULL,
    [Actionar]                BIT          NOT NULL,
    [Centru_de_cost_exceptie] CHAR (13)    NOT NULL,
    [Vechime_studii]          CHAR (6)     NOT NULL,
    [Loc_munca_precedent]     CHAR (40)    NOT NULL,
    [Loc_munca_nou]           CHAR (40)    NOT NULL,
    [Vechime_la_intrare]      CHAR (6)     NOT NULL,
    [Vechime_in_meserie]      CHAR (6)     NOT NULL,
    [Nr_contract]             CHAR (20)    NOT NULL,
    [Spor_cond_7]             FLOAT (53)   NOT NULL,
    [Spor_cond_8]             FLOAT (53)   NOT NULL,
    [Spor_cond_9]             FLOAT (53)   NOT NULL,
    [Spor_cond_10]            FLOAT (53)   NOT NULL
) ON [SYSS];

