CREATE TABLE [dbo].[antec] (
    [Comanda]  CHAR (20)  NOT NULL,
    [Versiune] INT        NOT NULL,
    [Data]     DATETIME   NOT NULL,
    [Stare]    CHAR (1)   NOT NULL,
    [Pret]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[antec]([Comanda] ASC, [Versiune] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Actualizare]
    ON [dbo].[antec]([Comanda] ASC, [Versiune] DESC);


GO
CREATE NONCLUSTERED INDEX [Comanda]
    ON [dbo].[antec]([Comanda] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_si_data]
    ON [dbo].[antec]([Comanda] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_si_stare]
    ON [dbo].[antec]([Comanda] ASC, [Stare] ASC);

