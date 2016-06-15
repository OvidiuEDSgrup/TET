CREATE TABLE [dbo].[RU_tinte_indicatori] (
    [ID_tinta]         INT           IDENTITY (1, 1) NOT NULL,
    [ID_indicator]     INT           NULL,
    [Descriere]        VARCHAR (MAX) NULL,
    [Data_inceput]     DATETIME      NULL,
    [Data_sfarsit]     DATETIME      NULL,
    [Interval_jos]     VARCHAR (10)  NULL,
    [Interval_sus]     VARCHAR (10)  NULL,
    [Valori]           VARCHAR (300) NULL,
    [Descriere_valori] VARCHAR (MAX) NULL,
    [ID_calificativ]   INT           NULL,
    CONSTRAINT [PK_RU_tinte_indicatori] PRIMARY KEY CLUSTERED ([ID_tinta] ASC),
    CONSTRAINT [FK_RU_calificativeTinta] FOREIGN KEY ([ID_calificativ]) REFERENCES [dbo].[RU_calificative] ([ID_calificativ]) ON UPDATE CASCADE,
    CONSTRAINT [FK_RU_indicatoriTinta] FOREIGN KEY ([ID_indicator]) REFERENCES [dbo].[RU_indicatori] ([ID_indicator]) ON UPDATE CASCADE
);

