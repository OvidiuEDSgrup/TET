CREATE TABLE [dbo].[categorii] (
    [Cod_categ]      VARCHAR (8)  NOT NULL,
    [Denumire_categ] VARCHAR (40) NOT NULL,
    [categ_tb]       VARCHAR (10) NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [cod]
    ON [dbo].[categorii]([Cod_categ] ASC);

