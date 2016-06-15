CREATE TABLE [dbo].[PontajElectronic] (
    [idPontajElectronic] INT         IDENTITY (1, 1) NOT NULL,
    [marca]              VARCHAR (6) NULL,
    [data_ora_intrare]   DATETIME    NULL,
    [data_ora_iesire]    DATETIME    NULL,
    [idJurnalPE]         INT         NULL,
    [detalii]            XML         NULL,
    PRIMARY KEY CLUSTERED ([idPontajElectronic] ASC),
    FOREIGN KEY ([idJurnalPE]) REFERENCES [dbo].[JurnalPontajElectronic] ([idJurnalPE])
);

