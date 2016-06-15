CREATE TABLE [dbo].[RU_rezultate] (
    [ID_rezultat]   INT         IDENTITY (1, 1) NOT NULL,
    [ID_evaluare]   INT         NULL,
    [Tip_evaluat]   VARCHAR (1) NULL,
    [ID_obiectiv]   INT         NULL,
    [ID_categ_comp] INT         NULL,
    [Media]         FLOAT (53)  NULL,
    CONSTRAINT [PK_RU_rezultate] PRIMARY KEY CLUSTERED ([ID_rezultat] ASC),
    CONSTRAINT [FK_RU_categ_comp1] FOREIGN KEY ([ID_categ_comp]) REFERENCES [dbo].[RU_categ_comp] ([ID_categ_comp]) ON UPDATE CASCADE,
    CONSTRAINT [FK_RU_evaluari1] FOREIGN KEY ([ID_evaluare]) REFERENCES [dbo].[RU_evaluari] ([ID_evaluare]) ON UPDATE CASCADE,
    CONSTRAINT [FK_RU_obiective2] FOREIGN KEY ([ID_obiectiv]) REFERENCES [dbo].[RU_obiective] ([ID_obiectiv]) ON UPDATE CASCADE
);

