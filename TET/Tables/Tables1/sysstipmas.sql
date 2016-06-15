CREATE TABLE [dbo].[sysstipmas] (
    [Host_id]        CHAR (10) NOT NULL,
    [Host_name]      CHAR (30) NOT NULL,
    [Aplicatia]      CHAR (30) NOT NULL,
    [Data_operarii]  DATETIME  NOT NULL,
    [Utilizator]     CHAR (10) NOT NULL,
    [Tip_act]        CHAR (1)  NOT NULL,
    [Cod]            CHAR (20) NOT NULL,
    [Denumire]       CHAR (60) NOT NULL,
    [tip_activitate] CHAR (1)  DEFAULT ('') NOT NULL
) ON [SYSS];

