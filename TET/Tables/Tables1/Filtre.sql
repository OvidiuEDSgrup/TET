CREATE TABLE [dbo].[Filtre] (
    [Cod_filtru]   CHAR (50)  NOT NULL,
    [Tabela]       CHAR (100) NOT NULL,
    [Numar]        CHAR (30)  NOT NULL,
    [Camp_afectat] CHAR (100) NOT NULL,
    [Fel_operator] CHAR (100) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Filtre]([Cod_filtru] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_bara]
    ON [dbo].[Filtre]([Tabela] ASC);

