CREATE TABLE [dbo].[StariContracte] (
    [idStare]       INT          IDENTITY (1, 1) NOT NULL,
    [tipContract]   VARCHAR (2)  NOT NULL,
    [stare]         INT          NOT NULL,
    [denumire]      VARCHAR (50) NULL,
    [detalii]       XML          NULL,
    [culoare]       VARCHAR (20) NULL,
    [modificabil]   BIT          NULL,
    [facturabil]    BIT          DEFAULT ((0)) NULL,
    [transportabil] BIT          DEFAULT ((0)) NULL,
    [transferabil]  BIT          DEFAULT ((0)) NULL,
    [inchisa]       BIT          DEFAULT ((0)) NULL,
    [actaditional]  BIT          DEFAULT ((0)) NULL,
    CONSTRAINT [PK_StariContracte] PRIMARY KEY CLUSTERED ([tipContract] ASC, [stare] ASC)
);

