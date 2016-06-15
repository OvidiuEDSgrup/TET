CREATE TABLE [dbo].[FisiereDocument] (
    [idFisier]   INT            IDENTITY (1, 1) NOT NULL,
    [tip]        VARCHAR (2)    NULL,
    [numar]      VARCHAR (20)   NULL,
    [data]       DATETIME       NULL,
    [fisier]     VARCHAR (2000) NULL,
    [observatii] VARCHAR (2000) NULL,
    CONSTRAINT [PK_FisiereDocument] PRIMARY KEY CLUSTERED ([idFisier] ASC)
);

