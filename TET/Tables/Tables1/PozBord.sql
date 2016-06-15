CREATE TABLE [dbo].[PozBord] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Numar]      CHAR (8)   NOT NULL,
    [Factura]    CHAR (20)  NOT NULL,
    [Suma]       FLOAT (53) NOT NULL,
    [Stare]      CHAR (1)   NOT NULL,
    [Explicatii] CHAR (50)  NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[PozBord]([Subunitate] ASC, [Numar] ASC, [Factura] ASC);

