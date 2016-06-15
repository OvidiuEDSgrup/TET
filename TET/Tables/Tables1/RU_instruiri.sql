CREATE TABLE [dbo].[RU_instruiri] (
    [ID_instruire] INT        IDENTITY (1, 1) NOT NULL,
    [Numar_fisa]   CHAR (10)  NULL,
    [Data]         DATETIME   NULL,
    [Data_inceput] DATETIME   NULL,
    [Data_sfarsit] DATETIME   NULL,
    [ID_curs]      INT        NULL,
    [Tematica]     CHAR (500) NULL,
    [Tip_trainer]  CHAR (2)   NULL,
    [Trainer]      CHAR (20)  NULL,
    [Tip_locatie]  CHAR (2)   NULL,
    [Locatie]      CHAR (20)  NULL,
    [Stare]        CHAR (1)   NULL,
    [Comanda]      CHAR (20)  NULL,
    CONSTRAINT [PK_RU_instruiri] PRIMARY KEY CLUSTERED ([ID_instruire] ASC),
    CONSTRAINT [FK_RU_cursuri_ins] FOREIGN KEY ([ID_curs]) REFERENCES [dbo].[RU_cursuri] ([ID_curs]) ON UPDATE CASCADE
);

