CREATE TABLE [dbo].[D112Asigurat] (
    [Data]         DATETIME    NULL,
    [cnpAsig]      CHAR (13)   NULL,
    [idAsig]       CHAR (6)    NULL,
    [numeAsig]     CHAR (75)   NULL,
    [prenAsig]     CHAR (75)   NULL,
    [cnpAnt]       CHAR (13)   NULL,
    [numeAnt]      CHAR (75)   NULL,
    [prenAnt]      CHAR (75)   NULL,
    [dataAng]      CHAR (10)   NULL,
    [dataSf]       CHAR (10)   NULL,
    [casaSn]       CHAR (2)    NULL,
    [asigCI]       CHAR (1)    NULL,
    [asigSO]       CHAR (1)    NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_cnp]
    ON [dbo].[D112Asigurat]([Data] ASC, [Loc_de_munca] ASC, [cnpAsig] ASC);

