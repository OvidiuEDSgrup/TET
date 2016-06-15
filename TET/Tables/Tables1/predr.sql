CREATE TABLE [dbo].[predr] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Tip]           CHAR (2)   NOT NULL,
    [Numar]         CHAR (20)  NOT NULL,
    [Cod]           CHAR (20)  NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Loc_predator]  CHAR (9)   NOT NULL,
    [Loc_primitor]  CHAR (9)   NOT NULL,
    [Cantitate]     FLOAT (53) NOT NULL,
    [Greutate]      FLOAT (53) NOT NULL,
    [Culoare]       CHAR (20)  NOT NULL,
    [Pret]          FLOAT (53) NOT NULL,
    [Comanda]       CHAR (13)  NOT NULL,
    [Numar_pozitie] INT        NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[predr]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Comanda] ASC, [Loc_predator] ASC, [Cod] ASC, [Numar_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Pentru_culegere]
    ON [dbo].[predr]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Comanda] ASC, [Numar_pozitie] ASC);

