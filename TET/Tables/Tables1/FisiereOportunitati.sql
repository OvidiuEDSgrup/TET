CREATE TABLE [dbo].[FisiereOportunitati] (
    [idFisierOp]     INT           NULL,
    [idOportunitate] INT           NULL,
    [fisier]         VARCHAR (200) NULL,
    [observatii]     VARCHAR (200) NULL,
    [data_operarii]  DATETIME      DEFAULT (getdate()) NULL
);

