CREATE TABLE [dbo].[sysscor] (
    [Host_id]            CHAR (10)  NOT NULL,
    [Host_name]          CHAR (30)  NOT NULL,
    [Aplicatia]          CHAR (30)  NOT NULL,
    [Data_operarii]      DATETIME   NOT NULL,
    [Utilizator]         CHAR (10)  NOT NULL,
    [Tip_act]            CHAR (1)   NOT NULL,
    [Data]               DATETIME   NOT NULL,
    [Marca]              CHAR (6)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Tip_corectie_venit] CHAR (2)   NOT NULL,
    [Suma_corectie]      FLOAT (53) NOT NULL,
    [Procent_corectie]   REAL       NOT NULL,
    [Suma_neta]          FLOAT (53) NOT NULL
) ON [SYSS];

