CREATE TABLE [dbo].[D112AsiguratD] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [D_1]          CHAR (5)    NULL,
    [D_2]          CHAR (10)   NULL,
    [D_3]          CHAR (5)    NULL,
    [D_4]          CHAR (10)   NULL,
    [D_5]          CHAR (10)   NULL,
    [D_6]          CHAR (10)   NULL,
    [D_7]          CHAR (10)   NULL,
    [D_8]          CHAR (13)   NULL,
    [D_9]          CHAR (2)    NULL,
    [D_10]         CHAR (2)    NULL,
    [D_11]         CHAR (3)    NULL,
    [D_12]         CHAR (2)    NULL,
    [D_13]         CHAR (10)   NULL,
    [D_14]         CHAR (2)    NULL,
    [D_15]         CHAR (2)    NULL,
    [D_16]         CHAR (2)    NULL,
    [D_17]         CHAR (6)    NULL,
    [D_18]         CHAR (3)    NULL,
    [D_19]         CHAR (11)   NULL,
    [D_20]         CHAR (15)   NULL,
    [D_21]         CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratD]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC, [D_1] ASC, [D_2] ASC, [D_6] ASC);

