CREATE TABLE [dbo].[TabInl] (
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
    ON [dbo].[TabInl]([Tip] ASC, [Numar_tabela] ASC);

