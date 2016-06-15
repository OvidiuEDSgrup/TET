CREATE TABLE [dbo].[RU_persoane_posturi] (
    [ID_pers_posturi] INT      IDENTITY (1, 1) NOT NULL,
    [ID_pers]         INT      NULL,
    [Cod_functie]     INT      NULL,
    [Datainc]         DATETIME NULL,
    [Datasf]          DATETIME NULL,
    CONSTRAINT [PK_RU_persoane_posturi] PRIMARY KEY CLUSTERED ([ID_pers_posturi] ASC),
    CONSTRAINT [FK_RU_persoane1] FOREIGN KEY ([ID_pers]) REFERENCES [dbo].[RU_persoane] ([ID_pers]) ON UPDATE CASCADE
);

