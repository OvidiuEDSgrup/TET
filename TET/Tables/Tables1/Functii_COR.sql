CREATE TABLE [dbo].[Functii_COR] (
    [Numar_curent] CHAR (6)   NOT NULL,
    [Cod_functie]  CHAR (6)   NOT NULL,
    [Denumire]     CHAR (250) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_functie]
    ON [dbo].[Functii_COR]([Cod_functie] ASC, [Numar_curent] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[Functii_COR]([Denumire] ASC);

