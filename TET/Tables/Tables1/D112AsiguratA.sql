CREATE TABLE [dbo].[D112AsiguratA] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [A_1]          CHAR (2)    NULL,
    [A_2]          CHAR (1)    NULL,
    [A_3]          CHAR (2)    NULL,
    [A_4]          CHAR (1)    NULL,
    [A_5]          CHAR (15)   NULL,
    [A_6]          CHAR (3)    NULL,
    [A_7]          CHAR (3)    NULL,
    [A_8]          CHAR (5)    NULL,
    [A_9]          CHAR (15)   NULL,
    [A_10]         CHAR (15)   NULL,
    [A_11]         CHAR (15)   NULL,
    [A_12]         CHAR (15)   NULL,
    [A_13]         CHAR (15)   NULL,
    [A_14]         CHAR (15)   NULL,
    [A_20]         CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratA]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC, [A_1] ASC, [A_3] ASC, [A_6] ASC);

