CREATE TABLE [dbo].[D112coAsigurati] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [tip]          CHAR (1)    NULL,
    [cnp]          CHAR (13)   NULL,
    [nume]         CHAR (75)   NULL,
    [prenume]      CHAR (75)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112coAsigurati]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC, [cnp] ASC);

