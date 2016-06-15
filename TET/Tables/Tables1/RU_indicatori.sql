CREATE TABLE [dbo].[RU_indicatori] (
    [ID_indicator]         INT           IDENTITY (1, 1) NOT NULL,
    [ID_domeniu]           INT           NULL,
    [Denumire]             VARCHAR (200) NULL,
    [Descriere]            VARCHAR (MAX) NULL,
    [Formula]              VARCHAR (200) NULL,
    [UM]                   VARCHAR (10)  NULL,
    [Tip]                  VARCHAR (1)   NULL,
    [Interval_jos]         VARCHAR (10)  NULL,
    [Interval_sus]         VARCHAR (10)  NULL,
    [Valori]               VARCHAR (300) NULL,
    [Descriere_valori]     VARCHAR (MAX) NULL,
    [Procent]              FLOAT (53)    NULL,
    [Stare]                VARCHAR (1)   NULL,
    [Sursa_documentare]    VARCHAR (100) NULL,
    [Responsabil_calcul]   INT           NULL,
    [Periodicitate_calcul] INT           NULL,
    CONSTRAINT [PK_RU_indicatori] PRIMARY KEY CLUSTERED ([ID_indicator] ASC),
    CONSTRAINT [FK_RU_domenii1] FOREIGN KEY ([ID_domeniu]) REFERENCES [dbo].[RU_domenii] ([ID_domeniu]) ON UPDATE CASCADE
);

