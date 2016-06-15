CREATE TABLE [dbo].[pozAntecalculatii_vechi] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [tip]        VARCHAR (1)  NOT NULL,
    [cod]        VARCHAR (20) NOT NULL,
    [cantitate]  FLOAT (53)   NULL,
    [pret]       FLOAT (53)   NULL,
    [idp]        INT          NULL,
    [detalii]    XML          NULL,
    [parinteTop] INT          NULL
);

