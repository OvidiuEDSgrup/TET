CREATE TABLE [dbo].[pozAntecalculatii] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [tip]        VARCHAR (1)  NOT NULL,
    [cod]        VARCHAR (20) NOT NULL,
    [cantitate]  FLOAT (53)   NULL,
    [pret]       FLOAT (53)   NULL,
    [idp]        INT          NULL,
    [detalii]    XML          NULL,
    [parinteTop] INT          NULL,
    CONSTRAINT [PK_pozAntecalculatii] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 20)
);

