CREATE TABLE [dbo].[speciflm] (
    [Loc_de_munca]   CHAR (9)  NOT NULL,
    [Tipul_comenzii] CHAR (1)  NOT NULL,
    [Marca]          CHAR (6)  NOT NULL,
    [Comanda]        CHAR (60) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Locmunca]
    ON [dbo].[speciflm]([Loc_de_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [Tiplocmunca]
    ON [dbo].[speciflm]([Tipul_comenzii] ASC, [Loc_de_munca] ASC);

