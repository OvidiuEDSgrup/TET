CREATE TABLE [dbo].[RU_furnizori_cursuri] (
    [ID_furnizor_curs] INT           IDENTITY (1, 1) NOT NULL,
    [ID_curs]          INT           NULL,
    [Tert]             CHAR (13)     NULL,
    [Pret]             FLOAT (53)    NULL,
    [UM]               CHAR (10)     NULL,
    [Explicatii]       VARCHAR (500) NULL,
    CONSTRAINT [PK_RU_furnizori_cursuri] PRIMARY KEY CLUSTERED ([ID_furnizor_curs] ASC),
    CONSTRAINT [FK_RU_cursurif] FOREIGN KEY ([ID_curs]) REFERENCES [dbo].[RU_cursuri] ([ID_curs]) ON UPDATE CASCADE
);

