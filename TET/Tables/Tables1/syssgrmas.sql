CREATE TABLE [dbo].[syssgrmas] (
    [Host_id]       CHAR (10) NOT NULL,
    [Host_name]     CHAR (30) NOT NULL,
    [Aplicatia]     CHAR (30) NOT NULL,
    [Data_operarii] DATETIME  NOT NULL,
    [Utilizator]    CHAR (10) NOT NULL,
    [Tip_act]       CHAR (1)  NOT NULL,
    [Grupa]         CHAR (20) NOT NULL,
    [Denumire]      CHAR (30) NOT NULL
) ON [SYSS];

