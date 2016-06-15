CREATE TABLE [dbo].[D112AsiguratB11] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [B11_1]        CHAR (2)    NULL,
    [B11_2]        CHAR (15)   NULL,
    [B11_3]        CHAR (15)   NULL,
    [B11_41]       CHAR (15)   NULL,
    [B11_42]       CHAR (15)   NULL,
    [B11_43]       CHAR (15)   NULL,
    [B11_5]        CHAR (15)   NULL,
    [B11_6]        CHAR (15)   NULL,
    [B11_71]       CHAR (15)   NULL,
    [B11_72]       CHAR (15)   NULL,
    [B11_73]       CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratB11]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC, [B11_1] ASC);

