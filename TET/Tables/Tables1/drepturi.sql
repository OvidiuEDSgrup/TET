CREATE TABLE [dbo].[drepturi] (
    [Drept]     CHAR (10) NOT NULL,
    [Nume]      CHAR (50) NOT NULL,
    [Publ]      BIT       NOT NULL,
    [Aplicatie] CHAR (2)  NOT NULL,
    [Atribuit]  BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Drept]
    ON [dbo].[drepturi]([Drept] ASC);


GO
CREATE NONCLUSTERED INDEX [Nume_drept]
    ON [dbo].[drepturi]([Nume] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Pe_aplicatii]
    ON [dbo].[drepturi]([Aplicatie] ASC, [Drept] ASC);

