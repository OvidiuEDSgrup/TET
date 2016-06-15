CREATE TABLE [dbo].[StocProd] (
    [Data]              DATETIME   NOT NULL,
    [Tip_stoc]          CHAR (2)   NOT NULL,
    [Loc_de_munca]      CHAR (9)   NOT NULL,
    [Comanda]           CHAR (13)  NOT NULL,
    [Cod_resursa]       CHAR (20)  NOT NULL,
    [Tip]               CHAR (1)   NOT NULL,
    [Culoare]           CHAR (20)  NOT NULL,
    [Stoc_initial]      FLOAT (53) NOT NULL,
    [Intrari]           FLOAT (53) NOT NULL,
    [Iesiri]            FLOAT (53) NOT NULL,
    [Stoc]              FLOAT (53) NOT NULL,
    [Diferenta]         FLOAT (53) NOT NULL,
    [Pret]              FLOAT (53) NOT NULL,
    [Valoare_materiale] FLOAT (53) NOT NULL,
    [Valoare_manopera]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[StocProd]([Data] ASC, [Tip_stoc] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Cod_resursa] ASC, [Tip] ASC, [Culoare] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_resursa]
    ON [dbo].[StocProd]([Data] ASC, [Tip_stoc] ASC, [Cod_resursa] ASC, [Stoc] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda]
    ON [dbo].[StocProd]([Comanda] ASC);

