CREATE TABLE [dbo].[syssrulsoldi] (
    [Host_id]       CHAR (10)    NOT NULL,
    [Host_name]     CHAR (30)    NOT NULL,
    [Aplicatia]     CHAR (30)    NOT NULL,
    [Data_operarii] DATETIME     NOT NULL,
    [Utilizator]    CHAR (10)    NOT NULL,
    [Tip_act]       CHAR (1)     NOT NULL,
    [Subunitate]    CHAR (9)     NOT NULL,
    [Cont]          VARCHAR (20) NULL,
    [Valuta]        CHAR (3)     NOT NULL,
    [Data]          DATETIME     NOT NULL,
    [Rulaj_debit]   FLOAT (53)   NOT NULL,
    [Rulaj_credit]  FLOAT (53)   NOT NULL
) ON [SYSS];

