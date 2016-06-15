CREATE TABLE [dbo].[RU_indicatori_obiective] (
    [ID_ind_ob]        INT           IDENTITY (1, 1) NOT NULL,
    [ID_obiectiv]      INT           NULL,
    [ID_indicator]     INT           NULL,
    [Data_inceput]     DATETIME      NULL,
    [Data_sfarsit]     DATETIME      NULL,
    [Interval_jos]     VARCHAR (10)  NULL,
    [Interval_sus]     VARCHAR (10)  NULL,
    [Valori]           VARCHAR (300) NULL,
    [Procent]          FLOAT (53)    NULL,
    [Descriere_valori] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_RU_indicatori_obiective] PRIMARY KEY CLUSTERED ([ID_ind_ob] ASC),
    CONSTRAINT [FK_RU_indicatori_obiectiveI] FOREIGN KEY ([ID_indicator]) REFERENCES [dbo].[RU_indicatori] ([ID_indicator]) ON UPDATE CASCADE,
    CONSTRAINT [FK_RU_indicatori_obiectiveO] FOREIGN KEY ([ID_obiectiv]) REFERENCES [dbo].[RU_obiective] ([ID_obiectiv])
);

