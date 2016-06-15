CREATE TABLE [dbo].[categpret] (
    [Categorie]       SMALLINT   NOT NULL,
    [Tip_categorie]   SMALLINT   NOT NULL,
    [Denumire]        CHAR (30)  NOT NULL,
    [In_valuta]       BIT        NOT NULL,
    [Cu_discount]     BIT        NOT NULL,
    [Suma]            FLOAT (53) NOT NULL,
    [categ_referinta] INT        NULL,
    [detalii]         XML        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CategPret]
    ON [dbo].[categpret]([Categorie] ASC);

