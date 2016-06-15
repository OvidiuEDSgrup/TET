CREATE TABLE [dbo].[SoldFacturiTLI] (
    [datalunii] DATETIME     NOT NULL,
    [tipf]      CHAR (1)     NOT NULL,
    [tert]      VARCHAR (20) NOT NULL,
    [factura]   VARCHAR (20) NOT NULL,
    [sold]      FLOAT (53)   NULL,
    [baza]      FLOAT (53)   NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [pSoldFacturiTLI]
    ON [dbo].[SoldFacturiTLI]([datalunii] ASC, [tipf] ASC, [tert] ASC, [factura] ASC);

