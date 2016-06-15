CREATE TABLE [dbo].[cfgOrdineElement1] (
    [categorie] VARCHAR (20) NULL,
    [element_1] VARCHAR (50) NULL,
    [ordine]    INT          NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [index_cfgOrdineElement1]
    ON [dbo].[cfgOrdineElement1]([categorie] ASC, [element_1] ASC);

