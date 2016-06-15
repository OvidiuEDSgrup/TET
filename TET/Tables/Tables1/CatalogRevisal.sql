CREATE TABLE [dbo].[CatalogRevisal] (
    [TipCatalog] CHAR (30)  NULL,
    [CodParinte] CHAR (50)  NULL,
    [Cod]        CHAR (60)  NULL,
    [Descriere]  CHAR (300) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Tip_codp_cod]
    ON [dbo].[CatalogRevisal]([TipCatalog] ASC, [CodParinte] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_cod]
    ON [dbo].[CatalogRevisal]([TipCatalog] ASC, [Cod] ASC);

