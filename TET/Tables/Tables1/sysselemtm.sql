CREATE TABLE [dbo].[sysselemtm] (
    [Host_id]       CHAR (10)   NOT NULL,
    [Host_name]     CHAR (30)   NOT NULL,
    [Aplicatia]     CHAR (30)   NOT NULL,
    [Data_operarii] DATETIME    NOT NULL,
    [Utilizator]    CHAR (10)   NOT NULL,
    [Tip_act]       CHAR (1)    NOT NULL,
    [Tip_masina]    CHAR (20)   NOT NULL,
    [Element]       CHAR (20)   NOT NULL,
    [Mod_calcul]    CHAR (1)    NOT NULL,
    [Formula]       CHAR (2000) NOT NULL,
    [Valoare]       FLOAT (53)  NOT NULL,
    [Ord_macheta]   SMALLINT    NOT NULL,
    [Ord_raport]    SMALLINT    NOT NULL,
    [Cu_totaluri]   BIT         NOT NULL,
    [Grupa]         CHAR (20)   NOT NULL
) ON [SYSS];

