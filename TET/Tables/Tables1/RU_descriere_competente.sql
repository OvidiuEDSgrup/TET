CREATE TABLE [dbo].[RU_descriere_competente] (
    [ID_desc_comp]   INT           IDENTITY (1, 1) NOT NULL,
    [ID_competenta]  INT           NULL,
    [Tip_componenta] INT           NULL,
    [Componenta]     VARCHAR (200) NULL,
    [Procent]        FLOAT (53)    NULL,
    [Descriere]      VARCHAR (MAX) NULL,
    CONSTRAINT [PK_RU_descriere_competente] PRIMARY KEY CLUSTERED ([ID_desc_comp] ASC),
    CONSTRAINT [FK_RU_competente7] FOREIGN KEY ([ID_competenta]) REFERENCES [dbo].[RU_competente] ([ID_competenta]) ON UPDATE CASCADE
);

