﻿CREATE TABLE [dbo].[syssdev] (
    [Host_id]           CHAR (10)  NOT NULL,
    [Host_name]         CHAR (30)  NOT NULL,
    [Aplicatia]         CHAR (30)  NOT NULL,
    [Data_operarii]     DATETIME   NOT NULL,
    [Utilizator]        CHAR (10)  NOT NULL,
    [Tip_act]           CHAR (1)   NOT NULL,
    [Cod_deviz]         CHAR (20)  NOT NULL,
    [Denumire_deviz]    CHAR (50)  NOT NULL,
    [Data_lansarii]     DATETIME   NOT NULL,
    [Data_inchiderii]   DATETIME   NOT NULL,
    [Obiect_deviz]      CHAR (20)  NOT NULL,
    [Obiectiv_deviz]    CHAR (20)  NOT NULL,
    [Executant]         CHAR (9)   NOT NULL,
    [Beneficiar]        CHAR (13)  NOT NULL,
    [Facturat]          BIT        NOT NULL,
    [Categorie_deviz]   CHAR (9)   NOT NULL,
    [Integral]          BIT        NOT NULL,
    [Valoare_deviz]     FLOAT (53) NOT NULL,
    [Valoare_realizari] FLOAT (53) NOT NULL,
    [Utilizator_dev]    CHAR (10)  NOT NULL,
    [Data_operarii_dev] DATETIME   NOT NULL,
    [Ora_operarii]      CHAR (6)   NOT NULL
) ON [SYSS];
