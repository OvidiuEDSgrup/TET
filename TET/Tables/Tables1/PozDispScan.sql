CREATE TABLE [dbo].[PozDispScan] (
    [tipPozitie]    VARCHAR (50) NULL,
    [barcode]       VARCHAR (50) NULL,
    [cantitate]     FLOAT (53)   NULL,
    [locatie]       VARCHAR (50) NULL,
    [utilizator]    VARCHAR (50) NULL,
    [detalii]       XML          NULL,
    [idPozScan]     INT          IDENTITY (1, 1) NOT NULL,
    [idPoz]         INT          NULL,
    [data_operarii] DATETIME     NULL,
    CONSTRAINT [PK_idPozScan] PRIMARY KEY CLUSTERED ([idPozScan] ASC),
    CONSTRAINT [FK_PozDispScan_PozDispOp] FOREIGN KEY ([idPoz]) REFERENCES [dbo].[PozDispOp] ([idPoz])
);

