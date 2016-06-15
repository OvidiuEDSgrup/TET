CREATE TABLE [dbo].[RU_competente_functii] (
    [ID_comp_functii] INT        IDENTITY (1, 1) NOT NULL,
    [ID_competenta]   INT        NULL,
    [Cod_functie]     CHAR (6)   NULL,
    [ID_categ_comp]   INT        NULL,
    [Pondere]         FLOAT (53) NULL,
    CONSTRAINT [PK_RU_competente_functii] PRIMARY KEY CLUSTERED ([ID_comp_functii] ASC),
    CONSTRAINT [FK_RU_categ_comp2] FOREIGN KEY ([ID_categ_comp]) REFERENCES [dbo].[RU_categ_comp] ([ID_categ_comp]),
    CONSTRAINT [FK_RU_competente_functii] FOREIGN KEY ([ID_competenta]) REFERENCES [dbo].[RU_competente] ([ID_competenta]) ON UPDATE CASCADE
);

