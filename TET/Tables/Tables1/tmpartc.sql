CREATE TABLE [dbo].[tmpartc] (
    [Numar_curent]          SMALLINT NOT NULL,
    [Articol_de_calculatie] CHAR (9) NOT NULL,
    [Ordinea_in_raport]     SMALLINT NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Articol]
    ON [dbo].[tmpartc]([Numar_curent] ASC, [Articol_de_calculatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Ordine]
    ON [dbo].[tmpartc]([Ordinea_in_raport] ASC);

