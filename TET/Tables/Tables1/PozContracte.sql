CREATE TABLE [dbo].[PozContracte] (
    [idPozContract] INT            IDENTITY (1, 1) NOT NULL,
    [idContract]    INT            NULL,
    [subtip]        VARCHAR (20)   NULL,
    [cod]           VARCHAR (20)   NULL,
    [grupa]         VARCHAR (20)   NULL,
    [cantitate]     FLOAT (53)     NULL,
    [pret]          FLOAT (53)     NULL,
    [discount]      FLOAT (53)     NULL,
    [termen]        DATETIME       NULL,
    [periodicitate] INT            NULL,
    [explicatii]    VARCHAR (8000) NULL,
    [cod_specific]  VARCHAR (20)   NULL,
    [detalii]       XML            NULL,
    [idPozLansare]  INT            NULL,
    [starePoz]      INT            NULL,
    CONSTRAINT [PK_PozContracte] PRIMARY KEY CLUSTERED ([idPozContract] ASC),
    CONSTRAINT [FK_PozContracte_idContract] FOREIGN KEY ([idContract]) REFERENCES [dbo].[Contracte] ([idContract])
);


GO
CREATE NONCLUSTERED INDEX [IX_idContract]
    ON [dbo].[PozContracte]([idContract] ASC);

