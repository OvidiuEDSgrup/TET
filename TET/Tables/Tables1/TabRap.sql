CREATE TABLE [dbo].[TabRap] (
    [Raport]        CHAR (60)  NOT NULL,
    [Adresa_raport] CHAR (200) NOT NULL,
    [Parametri]     CHAR (500) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Tip]           CHAR (1)   NOT NULL,
    [Aplicatie]     CHAR (2)   NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[TabRap]([Raport] ASC);


GO
CREATE NONCLUSTERED INDEX [Pe_aplicatie]
    ON [dbo].[TabRap]([Aplicatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Pe_utilizator]
    ON [dbo].[TabRap]([Utilizator] ASC);

