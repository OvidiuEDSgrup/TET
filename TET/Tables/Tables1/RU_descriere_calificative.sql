CREATE TABLE [dbo].[RU_descriere_calificative] (
    [ID_descriere]          INT           IDENTITY (1, 1) NOT NULL,
    [ID_calificativ]        INT           NOT NULL,
    [Descriere_calificativ] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_RU_descriere_calificative] PRIMARY KEY CLUSTERED ([ID_calificativ] ASC),
    CONSTRAINT [FK_RU_calificative] FOREIGN KEY ([ID_calificativ]) REFERENCES [dbo].[RU_calificative] ([ID_calificativ]) ON UPDATE CASCADE
);

