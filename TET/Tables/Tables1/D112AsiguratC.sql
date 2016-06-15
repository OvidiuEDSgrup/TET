CREATE TABLE [dbo].[D112AsiguratC] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [C_1]          CHAR (2)    NULL,
    [C_2]          CHAR (2)    NULL,
    [C_3]          CHAR (2)    NULL,
    [C_4]          CHAR (15)   NULL,
    [C_5]          CHAR (2)    NULL,
    [C_6]          CHAR (15)   NULL,
    [C_7]          CHAR (15)   NULL,
    [C_8]          CHAR (15)   NULL,
    [C_9]          CHAR (15)   NULL,
    [C_10]         CHAR (15)   NULL,
    [C_11]         CHAR (15)   NULL,
    [C_17]         CHAR (2)    NULL,
    [C_18]         CHAR (15)   NULL,
    [C_19]         CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratC]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC);

