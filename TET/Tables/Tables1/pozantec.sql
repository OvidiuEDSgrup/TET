CREATE TABLE [dbo].[pozantec] (
    [Comanda]  CHAR (20)  NOT NULL,
    [Versiune] INT        NOT NULL,
    [Element]  CHAR (20)  NOT NULL,
    [Valoare]  FLOAT (53) NOT NULL,
    [NrOrdine] REAL       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozantec]([Comanda] ASC, [Versiune] ASC, [Element] ASC);


GO
CREATE NONCLUSTERED INDEX [Numa_de_ordine]
    ON [dbo].[pozantec]([NrOrdine] ASC);

