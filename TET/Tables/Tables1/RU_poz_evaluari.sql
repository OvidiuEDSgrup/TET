CREATE TABLE [dbo].[RU_poz_evaluari] (
    [ID_poz_evaluare] INT         IDENTITY (1, 1) NOT NULL,
    [ID_evaluare]     INT         NULL,
    [Tip_evaluat]     VARCHAR (2) NULL,
    [ID_competenta]   INT         NULL,
    [ID_obiectiv]     INT         NULL,
    [ID_indicator]    INT         NULL,
    [Data_inceput]    DATETIME    NULL,
    [Data_sfarsit]    DATETIME    NULL,
    [ID_evaluator]    INT         NULL,
    [Data_evaluare]   DATETIME    NULL,
    [ID_calificativ]  INT         NULL,
    [Procent]         FLOAT (53)  NULL,
    [Nota]            FLOAT (53)  NULL,
    [Data_operarii]   DATETIME    NULL,
    [Ora_operarii]    CHAR (6)    NULL,
    [Utilizator]      CHAR (10)   NULL,
    CONSTRAINT [PK_RU_poz_evaluari] PRIMARY KEY CLUSTERED ([ID_poz_evaluare] ASC),
    CONSTRAINT [FK_RU_competente1] FOREIGN KEY ([ID_competenta]) REFERENCES [dbo].[RU_competente] ([ID_competenta]) ON UPDATE CASCADE,
    CONSTRAINT [FK_RU_evaluari] FOREIGN KEY ([ID_evaluare]) REFERENCES [dbo].[RU_evaluari] ([ID_evaluare]) ON UPDATE CASCADE
);

