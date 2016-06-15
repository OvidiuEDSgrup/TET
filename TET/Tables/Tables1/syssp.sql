﻿CREATE TABLE [dbo].[syssp] (
    [Host_id]            CHAR (10)  NOT NULL,
    [Host_name]          CHAR (30)  NOT NULL,
    [Aplicatia]          CHAR (30)  NOT NULL,
    [Data_stergerii]     DATETIME   NOT NULL,
    [Stergator]          CHAR (10)  NOT NULL,
    [Tip_parametru]      CHAR (2)   NOT NULL,
    [Parametru]          CHAR (9)   NOT NULL,
    [Denumire_parametru] CHAR (30)  NOT NULL,
    [Val_logica]         BIT        NOT NULL,
    [Val_numerica]       FLOAT (53) NOT NULL,
    [Val_alfanumerica]   CHAR (200) NOT NULL
) ON [SYSS];

