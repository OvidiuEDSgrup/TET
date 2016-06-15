CREATE TABLE [dbo].[RU_calificative] (
    [ID_calificativ]  INT           IDENTITY (1, 1) NOT NULL,
    [Data_inceput]    DATETIME      NULL,
    [Data_sfarsit]    DATETIME      NULL,
    [Calificativ]     INT           NULL,
    [Nota_inferioara] FLOAT (53)    NULL,
    [Nota_superioara] FLOAT (53)    NULL,
    [Nivel_realizare] VARCHAR (100) NULL,
    CONSTRAINT [PK_RU_calificativ] PRIMARY KEY CLUSTERED ([ID_calificativ] ASC)
);

