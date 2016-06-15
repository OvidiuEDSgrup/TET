CREATE TABLE [dbo].[articole] (
    [Cod_grupa]        CHAR (1)  NOT NULL,
    [Cod_articol]      CHAR (20) NOT NULL,
    [Denumire_articol] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Articol]
    ON [dbo].[articole]([Cod_grupa] ASC, [Cod_articol] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[articole]([Denumire_articol] ASC);

