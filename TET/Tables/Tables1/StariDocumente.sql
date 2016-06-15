CREATE TABLE [dbo].[StariDocumente] (
    [idStare]      INT           IDENTITY (1, 1) NOT NULL,
    [tipDocument]  VARCHAR (5)   NULL,
    [stare]        INT           NULL,
    [denumire]     VARCHAR (100) NULL,
    [culoare]      VARCHAR (10)  NULL,
    [modificabil]  BIT           NULL,
    [detalii]      XML           NULL,
    [inCurs]       BIT           NULL,
    [initializare] BIT           NULL,
    PRIMARY KEY CLUSTERED ([idStare] ASC)
);

