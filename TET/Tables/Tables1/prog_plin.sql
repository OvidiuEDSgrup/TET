CREATE TABLE [dbo].[prog_plin] (
    [Tip]            CHAR (1)   NOT NULL,
    [Element]        CHAR (1)   NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Factura]        CHAR (20)  NOT NULL,
    [Explicatii]     CHAR (50)  NOT NULL,
    [Suma]           FLOAT (53) NOT NULL,
    [Valuta]         CHAR (3)   NOT NULL,
    [Suma_valuta]    FLOAT (53) NOT NULL,
    [Stare]          SMALLINT   NOT NULL,
    [Data_scadentei] DATETIME   NOT NULL,
    [Bifat]          BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[prog_plin]([Tip] ASC, [Element] ASC, [Data] ASC, [Tert] ASC, [Factura] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Data]
    ON [dbo].[prog_plin]([Data] ASC, [Element] DESC, [Tip] ASC, [Tert] ASC, [Factura] ASC);


GO
CREATE NONCLUSTERED INDEX [Tert]
    ON [dbo].[prog_plin]([Tip] ASC, [Element] ASC, [Tert] ASC);

