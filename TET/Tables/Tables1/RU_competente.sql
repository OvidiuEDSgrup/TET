CREATE TABLE [dbo].[RU_competente] (
    [ID_competenta]          INT           IDENTITY (1, 1) NOT NULL,
    [Denumire]               VARCHAR (200) NULL,
    [ID_competenta_parinte]  INT           NULL,
    [ID_domeniu]             INT           NULL,
    [Tip_competenta]         INT           NULL,
    [Tip_calcul_calificativ] INT           NULL,
    [Procent]                FLOAT (53)    NULL,
    [Descriere]              VARCHAR (MAX) NULL,
    [Detalii]                XML           NULL,
    CONSTRAINT [PK_RU_competente] PRIMARY KEY CLUSTERED ([ID_competenta] ASC),
    CONSTRAINT [FK_RU_domenii] FOREIGN KEY ([ID_domeniu]) REFERENCES [dbo].[RU_domenii] ([ID_domeniu]) ON UPDATE CASCADE
);

