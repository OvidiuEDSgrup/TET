CREATE TABLE [dbo].[JurnalPontajElectronic] (
    [idJurnalPE] INT            IDENTITY (1, 1) NOT NULL,
    [operatie]   VARCHAR (1000) NULL,
    [data]       DATETIME       NULL,
    [utilizator] VARCHAR (100)  NULL,
    [explicatii] VARCHAR (2000) NULL,
    PRIMARY KEY CLUSTERED ([idJurnalPE] ASC)
);

