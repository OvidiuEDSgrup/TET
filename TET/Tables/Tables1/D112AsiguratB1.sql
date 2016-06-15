CREATE TABLE [dbo].[D112AsiguratB1] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [B1_1]         CHAR (2)    NULL,
    [B1_2]         CHAR (1)    NULL,
    [B1_3]         CHAR (2)    NULL,
    [B1_4]         CHAR (1)    NULL,
    [B1_5]         CHAR (15)   NULL,
    [B1_6]         CHAR (3)    NULL,
    [B1_7]         CHAR (3)    NULL,
    [B1_8]         CHAR (3)    NULL,
    [B1_9]         CHAR (5)    NULL,
    [B1_10]        CHAR (15)   NULL,
    [B1_15]        CHAR (2)    NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratB1]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC, [B1_1] ASC, [B1_3] ASC, [B1_6] ASC);

