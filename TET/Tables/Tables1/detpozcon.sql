CREATE TABLE [dbo].[detpozcon] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Tip]           CHAR (2)   NOT NULL,
    [Contract]      CHAR (20)  NOT NULL,
    [Tert]          CHAR (13)  NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Numar_pozitie] INT        NOT NULL,
    [Numar_ordine]  INT        NOT NULL,
    [Obiect]        CHAR (20)  NOT NULL,
    [Punct_livrare] CHAR (5)   NOT NULL,
    [Comanda]       CHAR (13)  NOT NULL,
    [Versiune]      INT        NOT NULL,
    [Stare]         CHAR (1)   NOT NULL,
    [Termen]        DATETIME   NOT NULL,
    [Data_inceput]  DATETIME   NOT NULL,
    [Data_sfarsit]  DATETIME   NOT NULL,
    [Garantie]      CHAR (30)  NOT NULL,
    [Observatii]    CHAR (200) NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Data1]         DATETIME   NOT NULL,
    [Data2]         DATETIME   NOT NULL,
    [Info1]         CHAR (200) NOT NULL,
    [Info2]         CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[detpozcon]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Data] ASC, [Numar_pozitie] ASC, [Numar_ordine] ASC);


GO
CREATE NONCLUSTERED INDEX [Obiect]
    ON [dbo].[detpozcon]([Obiect] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda]
    ON [dbo].[detpozcon]([Comanda] ASC);

