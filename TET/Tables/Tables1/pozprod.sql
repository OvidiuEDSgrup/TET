CREATE TABLE [dbo].[pozprod] (
    [Comanda]             CHAR (13)  NOT NULL,
    [Cod]                 CHAR (20)  NOT NULL,
    [Comanda_livrare]     CHAR (20)  NOT NULL,
    [Data_comenzii]       DATETIME   NOT NULL,
    [Beneficiar]          CHAR (13)  NOT NULL,
    [Cantitate_comandata] FLOAT (53) NOT NULL,
    [Cantitate_realizata] FLOAT (53) NOT NULL,
    [Cantitate_livrata]   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozprod]([Comanda] ASC, [Cod] ASC, [Comanda_livrare] ASC, [Data_comenzii] ASC, [Beneficiar] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_productie]
    ON [dbo].[pozprod]([Comanda] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_livrare]
    ON [dbo].[pozprod]([Comanda_livrare] ASC, [Data_comenzii] ASC, [Beneficiar] ASC, [Cod] ASC);

