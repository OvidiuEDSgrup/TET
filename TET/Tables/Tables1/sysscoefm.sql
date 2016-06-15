CREATE TABLE [dbo].[sysscoefm] (
    [Host_id]       CHAR (10)  NOT NULL,
    [Host_name]     CHAR (30)  NOT NULL,
    [Aplicatia]     CHAR (30)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Tip_act]       CHAR (1)   NOT NULL,
    [Masina]        CHAR (20)  NOT NULL,
    [Coeficient]    CHAR (20)  NOT NULL,
    [Valoare]       FLOAT (53) NOT NULL,
    [Interval]      FLOAT (53) NOT NULL
) ON [SYSS];

