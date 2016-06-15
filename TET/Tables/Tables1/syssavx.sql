CREATE TABLE [dbo].[syssavx] (
    [Host_id]              CHAR (10)  NOT NULL,
    [Host_name]            CHAR (30)  NOT NULL,
    [Aplicatia]            CHAR (30)  NOT NULL,
    [Data_operarii]        DATETIME   NOT NULL,
    [Utilizator]           CHAR (10)  NOT NULL,
    [Tip_act]              CHAR (1)   NOT NULL,
    [Marca]                CHAR (6)   NOT NULL,
    [Data]                 DATETIME   NOT NULL,
    [Ore_lucrate_la_avans] SMALLINT   NOT NULL,
    [Suma_avans]           FLOAT (53) NOT NULL,
    [Premiu_la_avans]      FLOAT (53) NOT NULL
) ON [SYSS];

