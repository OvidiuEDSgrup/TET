CREATE TABLE [dbo].[RU_evaluari] (
    [ID_evaluare]    INT         IDENTITY (1, 1) NOT NULL,
    [Tip]            VARCHAR (2) NULL,
    [Numar_fisa]     CHAR (10)   NULL,
    [Data]           DATETIME    NULL,
    [ID_evaluat]     INT         NULL,
    [ID_evaluator]   INT         NULL,
    [An_evaluat]     INT         NULL,
    [ID_calificativ] INT         NULL,
    [Media]          FLOAT (53)  NULL,
    CONSTRAINT [PK_RU_evaluari] PRIMARY KEY CLUSTERED ([ID_evaluare] ASC),
    CONSTRAINT [FK_RU_evaluari_calificative] FOREIGN KEY ([ID_calificativ]) REFERENCES [dbo].[RU_calificative] ([ID_calificativ]) ON UPDATE CASCADE,
    CONSTRAINT [FK_RU_persoane2] FOREIGN KEY ([ID_evaluat]) REFERENCES [dbo].[RU_persoane] ([ID_pers]) ON UPDATE CASCADE
);

