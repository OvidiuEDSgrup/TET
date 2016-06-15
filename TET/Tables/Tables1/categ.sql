CREATE TABLE [dbo].[categ] (
    [Categorie] SMALLINT  NOT NULL,
    [Denumire]  CHAR (30) NOT NULL,
    [Cota_TVA]  REAL      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Categorie]
    ON [dbo].[categ]([Categorie] ASC);

