﻿CREATE TABLE [dbo].[sysspozactiv] (
    [Host_id]        CHAR (10)  NOT NULL,
    [Host_name]      CHAR (30)  NOT NULL,
    [Aplicatia]      CHAR (30)  NOT NULL,
    [Data_stergerii] DATETIME   NOT NULL,
    [Stergator]      CHAR (10)  NOT NULL,
    [Tip_act]        CHAR (1)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Fisa]           CHAR (20)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Numar_pozitie]  INT        NOT NULL,
    [Traseu]         CHAR (20)  NOT NULL,
    [Plecare]        CHAR (30)  NOT NULL,
    [Data_plecarii]  DATETIME   NOT NULL,
    [Ora_plecarii]   CHAR (6)   NOT NULL,
    [Sosire]         CHAR (30)  NOT NULL,
    [Data_sosirii]   DATETIME   NOT NULL,
    [Ora_sosirii]    CHAR (6)   NOT NULL,
    [Explicatii]     CHAR (50)  NOT NULL,
    [Comanda_benef]  CHAR (13)  NOT NULL,
    [Lm_beneficiar]  CHAR (9)   NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Marca]          CHAR (6)   NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Alfa1]          CHAR (50)  NOT NULL,
    [Alfa2]          CHAR (50)  NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Data1]          DATETIME   NOT NULL
) ON [SYSS];

