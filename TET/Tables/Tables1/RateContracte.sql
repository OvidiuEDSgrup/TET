CREATE TABLE [dbo].[RateContracte] (
    [idRataContract] INT          IDENTITY (1, 1) NOT NULL,
    [idContract]     INT          NULL,
    [nr_rata]        INT          NULL,
    [cod]            VARCHAR (20) NULL,
    [suma]           FLOAT (53)   NULL,
    [detalii]        XML          NULL,
    CONSTRAINT [PK_RateContracte] PRIMARY KEY CLUSTERED ([idRataContract] ASC),
    CONSTRAINT [FK_RateContracte_idContract] FOREIGN KEY ([idContract]) REFERENCES [dbo].[Contracte] ([idContract])
);

