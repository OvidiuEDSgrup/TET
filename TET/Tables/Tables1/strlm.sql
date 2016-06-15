CREATE TABLE [dbo].[strlm] (
    [Nivel]         SMALLINT  NOT NULL,
    [Denumire]      CHAR (30) NOT NULL,
    [Lungime]       SMALLINT  NOT NULL,
    [Documente]     BIT       NOT NULL,
    [Mijloace_fixe] BIT       NOT NULL,
    [Salarii]       BIT       NOT NULL,
    [Costuri]       BIT       NOT NULL,
    [Produse]       BIT       NOT NULL,
    [Devize]        BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Nivel]
    ON [dbo].[strlm]([Nivel] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Lungime]
    ON [dbo].[strlm]([Lungime] ASC);

