CREATE TABLE [dbo].[syssca] (
    [Host_id]       CHAR (10)  NOT NULL,
    [Host_name]     CHAR (30)  NOT NULL,
    [Aplicatia]     CHAR (30)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Tip_act]       CHAR (1)   NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Marca]         CHAR (6)   NOT NULL,
    [Tip_concediu]  CHAR (1)   NOT NULL,
    [Data_inceput]  DATETIME   NOT NULL,
    [Data_sfarsit]  DATETIME   NOT NULL,
    [Zile]          SMALLINT   NOT NULL,
    [Introd_manual] BIT        NOT NULL,
    [Indemnizatie]  FLOAT (53) NOT NULL
) ON [SYSS];

