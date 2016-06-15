CREATE TABLE [dbo].[yso_TabInl] (
    [Tip]            SMALLINT  NOT NULL,
    [Numar_tabela]   INT       NOT NULL,
    [Denumire_magic] CHAR (30) NOT NULL,
    [Denumire_SQL]   CHAR (30) NOT NULL,
    [Camp1]          CHAR (30) NOT NULL,
    [Camp2]          CHAR (30) NOT NULL,
    [Inlocuiesc]     CHAR (2)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [p]
    ON [dbo].[yso_TabInl]([Tip] ASC, [Numar_tabela] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Denumire_SQL]
    ON [dbo].[yso_TabInl]([Tip] ASC, [Denumire_SQL] ASC) WITH (FILLFACTOR = 80);

