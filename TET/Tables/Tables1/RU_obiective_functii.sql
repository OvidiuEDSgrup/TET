CREATE TABLE [dbo].[RU_obiective_functii] (
    [ID_ob_functii] INT        IDENTITY (1, 1) NOT NULL,
    [ID_obiectiv]   INT        NULL,
    [Cod_functie]   CHAR (6)   NULL,
    [Pondere]       FLOAT (53) NULL,
    CONSTRAINT [PK_RU_obiective_functii] PRIMARY KEY CLUSTERED ([ID_ob_functii] ASC),
    CONSTRAINT [FK_RU_obiective] FOREIGN KEY ([ID_obiectiv]) REFERENCES [dbo].[RU_obiective] ([ID_obiectiv]) ON UPDATE CASCADE
);

