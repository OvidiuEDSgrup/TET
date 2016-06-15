CREATE TABLE [dbo].[D112AsiguratB234] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [B2_1]         CHAR (1)    NULL,
    [B2_2]         CHAR (2)    NULL,
    [B2_3]         CHAR (2)    NULL,
    [B2_4]         CHAR (2)    NULL,
    [B2_5]         CHAR (15)   NULL,
    [B2_6]         CHAR (15)   NULL,
    [B2_7]         CHAR (15)   NULL,
    [B3_1]         CHAR (2)    NULL,
    [B3_2]         CHAR (2)    NULL,
    [B3_3]         CHAR (2)    NULL,
    [B3_4]         CHAR (2)    NULL,
    [B3_5]         CHAR (2)    NULL,
    [B3_6]         CHAR (2)    NULL,
    [B3_7]         CHAR (15)   NULL,
    [B3_8]         CHAR (2)    NULL,
    [B3_9]         CHAR (15)   NULL,
    [B3_10]        CHAR (15)   NULL,
    [B3_11]        CHAR (15)   NULL,
    [B3_12]        CHAR (15)   NULL,
    [B3_13]        CHAR (15)   NULL,
    [B4_1]         CHAR (2)    NULL,
    [B4_2]         CHAR (2)    NULL,
    [B4_3]         CHAR (15)   NULL,
    [B4_4]         CHAR (15)   NULL,
    [B4_5]         CHAR (15)   NULL,
    [B4_6]         CHAR (15)   NULL,
    [B4_7]         CHAR (15)   NULL,
    [B4_8]         CHAR (15)   NULL,
    [B4_14]        CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratB234]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC);

