CREATE TABLE [dbo].[Provizioane] (
    [idProvizion] INT          IDENTITY (1, 1) NOT NULL,
    [datalunii]   DATETIME     NULL,
    [tert]        VARCHAR (20) NULL,
    [factura]     VARCHAR (20) NULL,
    [procent]     FLOAT (53)   NULL,
    [debit]       FLOAT (53)   NULL,
    [credit]      FLOAT (53)   NULL,
    [cont]        VARCHAR (20) NULL,
    [idPozADoc]   INT          NULL,
    [idPozNCon]   INT          NULL
);

