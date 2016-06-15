CREATE TABLE [dbo].[lansutil] (
    [Tip_utilaj]                CHAR (20)  NOT NULL,
    [Numar_de_inventar]         CHAR (13)  NOT NULL,
    [Comanda]                   CHAR (13)  NOT NULL,
    [Data_inceput]              DATETIME   NOT NULL,
    [Ora_de_inceput]            CHAR (6)   NOT NULL,
    [Data_sfarsit]              DATETIME   NOT NULL,
    [Ora_sfarsit]               CHAR (6)   NOT NULL,
    [Cantitate]                 FLOAT (53) NOT NULL,
    [Norma_de_productie_pe_ora] FLOAT (53) NOT NULL,
    [Stare]                     CHAR (1)   NOT NULL,
    [Cauza_oprire]              CHAR (1)   NOT NULL,
    [Nr_mersuri]                REAL       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[lansutil]([Tip_utilaj] ASC, [Numar_de_inventar] ASC, [Comanda] ASC, [Data_inceput] ASC, [Ora_de_inceput] ASC);


GO
CREATE NONCLUSTERED INDEX [Data_inceput]
    ON [dbo].[lansutil]([Data_inceput] ASC, [Ora_de_inceput] ASC, [Numar_de_inventar] ASC, [Comanda] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda]
    ON [dbo].[lansutil]([Comanda] ASC, [Numar_de_inventar] ASC, [Data_inceput] ASC);

