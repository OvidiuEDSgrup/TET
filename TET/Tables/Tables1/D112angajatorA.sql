CREATE TABLE [dbo].[D112angajatorA] (
    [Data]         DATETIME    NULL,
    [A_codOblig]   CHAR (3)    NULL,
    [A_codBugetar] CHAR (10)   NULL,
    [A_datorat]    CHAR (15)   NULL,
    [A_deductibil] CHAR (15)   NULL,
    [A_plata]      CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_CodOblig]
    ON [dbo].[D112angajatorA]([Data] ASC, [Loc_de_munca] ASC, [A_codOblig] ASC);

