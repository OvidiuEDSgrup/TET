CREATE TABLE [dbo].[nete] (
    [Data]         DATETIME   NOT NULL,
    [Loc_de_munca] CHAR (9)   NOT NULL,
    [Comanda]      CHAR (13)  NOT NULL,
    [Procent]      REAL       NOT NULL,
    [Cantitate]    FLOAT (53) NOT NULL,
    [Valoare]      FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[nete]([Data] ASC, [Loc_de_munca] ASC, [Comanda] ASC);

