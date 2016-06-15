CREATE TABLE [dbo].[RU_cursuri] (
    [ID_curs]        INT           IDENTITY (1, 1) NOT NULL,
    [Denumire]       CHAR (100)    NULL,
    [Durata]         INT           NULL,
    [Periodicitate]  INT           NULL,
    [Utilitate]      VARCHAR (500) NULL,
    [ID_domeniu]     INT           NULL,
    [Email]          VARCHAR (150) NULL,
    [Tip_curs]       CHAR (1)      NULL,
    [Tip_competenta] CHAR (1)      NULL,
    CONSTRAINT [PK_RU_cursuri] PRIMARY KEY CLUSTERED ([ID_curs] ASC),
    CONSTRAINT [FK_RU_domeniic] FOREIGN KEY ([ID_domeniu]) REFERENCES [dbo].[RU_domenii] ([ID_domeniu]) ON UPDATE CASCADE
);

