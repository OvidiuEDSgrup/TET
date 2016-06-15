CREATE TABLE [dbo].[FisiereContract] (
    [idFisier]      INT            IDENTITY (1, 1) NOT NULL,
    [idPozContract] INT            NULL,
    [idContract]    INT            NULL,
    [fisier]        VARCHAR (2000) NULL,
    [observatii]    VARCHAR (2000) NULL,
    CONSTRAINT [PK_FisiereContract] PRIMARY KEY CLUSTERED ([idFisier] ASC),
    FOREIGN KEY ([idContract]) REFERENCES [dbo].[Contracte] ([idContract]),
    FOREIGN KEY ([idPozContract]) REFERENCES [dbo].[PozContracte] ([idPozContract]),
    CONSTRAINT [FK_FisiereContract_idContract] FOREIGN KEY ([idContract]) REFERENCES [dbo].[Contracte] ([idContract])
);

