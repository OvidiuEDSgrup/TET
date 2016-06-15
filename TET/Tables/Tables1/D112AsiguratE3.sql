CREATE TABLE [dbo].[D112AsiguratE3] (
    [Data]         DATETIME     NULL,
    [Loc_de_munca] VARCHAR (9)  NULL,
    [cnpAsig]      CHAR (13)    NULL,
    [E3_1]         VARCHAR (1)  NULL,
    [E3_2]         VARCHAR (2)  NULL,
    [E3_3]         VARCHAR (1)  NULL,
    [E3_4]         VARCHAR (1)  NULL,
    [E3_5]         VARCHAR (7)  NULL,
    [E3_6]         VARCHAR (7)  NULL,
    [E3_7]         VARCHAR (3)  NULL,
    [E3_8]         VARCHAR (15) NULL,
    [E3_9]         VARCHAR (15) NULL,
    [E3_10]        VARCHAR (15) NULL,
    [E3_11]        VARCHAR (15) NULL,
    [E3_12]        VARCHAR (15) NULL,
    [E3_13]        VARCHAR (15) NULL,
    [E3_14]        VARCHAR (15) NULL,
    [E3_15]        VARCHAR (15) NULL,
    [E3_16]        VARCHAR (15) NULL,
    [idPozitie]    INT          IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PozAsiguratE3]
    ON [dbo].[D112AsiguratE3]([idPozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112AsiguratE3]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC, [E3_1] ASC, [E3_2] ASC, [E3_3] ASC, [E3_4] ASC);

