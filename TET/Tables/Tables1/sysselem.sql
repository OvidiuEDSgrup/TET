CREATE TABLE [dbo].[sysselem] (
    [Host_id]       CHAR (10)  NOT NULL,
    [Host_name]     CHAR (30)  NOT NULL,
    [Aplicatia]     CHAR (30)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Tip_act]       CHAR (1)   NOT NULL,
    [Cod]           CHAR (20)  NOT NULL,
    [Denumire]      CHAR (60)  NOT NULL,
    [Tip]           CHAR (1)   NOT NULL,
    [UM]            CHAR (3)   NOT NULL,
    [UM2]           CHAR (3)   NOT NULL,
    [Interval]      FLOAT (53) NOT NULL
) ON [SYSS];

