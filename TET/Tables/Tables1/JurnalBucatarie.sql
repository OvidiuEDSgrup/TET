CREATE TABLE [dbo].[JurnalBucatarie] (
    [idPozContract] INT      NULL,
    [stare]         INT      NULL,
    [dataora]       DATETIME DEFAULT (getdate()) NULL
);

