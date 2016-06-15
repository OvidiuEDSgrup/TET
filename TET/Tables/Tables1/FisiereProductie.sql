CREATE TABLE [dbo].[FisiereProductie] (
    [idFisier]        INT           IDENTITY (1, 1) NOT NULL,
    [fisier]          VARCHAR (300) NULL,
    [observatii]      VARCHAR (300) NULL,
    [idPozTehnologie] INT           NULL,
    [idPozLansare]    INT           NULL,
    [idPozRealizare]  INT           NULL,
    [detalii]         XML           NULL
);

