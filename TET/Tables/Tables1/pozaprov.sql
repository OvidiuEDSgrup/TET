CREATE TABLE [dbo].[pozaprov] (
    [Contract]          CHAR (20)  NOT NULL,
    [Data]              DATETIME   NOT NULL,
    [Furnizor]          CHAR (13)  NOT NULL,
    [Cod]               CHAR (20)  NOT NULL,
    [Comanda_livrare]   CHAR (20)  NOT NULL,
    [Data_comenzii]     DATETIME   NOT NULL,
    [Beneficiar]        CHAR (13)  NOT NULL,
    [Cant_comandata]    FLOAT (53) NOT NULL,
    [Cant_receptionata] FLOAT (53) NOT NULL,
    [Cant_realizata]    FLOAT (53) NOT NULL,
    [Tip]               CHAR (2)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal_pozaprov]
    ON [dbo].[pozaprov]([Contract] ASC, [Data] ASC, [Furnizor] ASC, [Cod] ASC, [Tip] ASC, [Comanda_livrare] ASC, [Data_comenzii] ASC, [Beneficiar] ASC);


GO
CREATE NONCLUSTERED INDEX [Pe_furnizor]
    ON [dbo].[pozaprov]([Contract] ASC, [Data] ASC, [Furnizor] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Pe_beneficiar]
    ON [dbo].[pozaprov]([Tip] ASC, [Comanda_livrare] ASC, [Data_comenzii] ASC, [Beneficiar] ASC, [Cod] ASC);

