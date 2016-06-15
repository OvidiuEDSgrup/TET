CREATE TABLE [dbo].[RU_cursuri_functii] (
    [ID_curs_functie] INT         IDENTITY (1, 1) NOT NULL,
    [Cod_functie]     VARCHAR (6) NULL,
    [ID_curs]         INT         NULL,
    CONSTRAINT [PK_RU_cursuri_functii] PRIMARY KEY CLUSTERED ([ID_curs_functie] ASC),
    CONSTRAINT [FK_RU_cursuri] FOREIGN KEY ([ID_curs]) REFERENCES [dbo].[RU_cursuri] ([ID_curs]) ON UPDATE CASCADE
);

