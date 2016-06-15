CREATE TABLE [dbo].[antecman] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Comanda]            CHAR (20)  NOT NULL,
    [Cod_produs]         CHAR (20)  NOT NULL,
    [Cod_tata]           CHAR (20)  NOT NULL,
    [Cod_operatie]       CHAR (20)  NOT NULL,
    [Numar_operatie]     SMALLINT   NOT NULL,
    [Cantitate_necesara] FLOAT (53) NOT NULL,
    [Pret]               FLOAT (53) NOT NULL,
    [Numar_fisa]         CHAR (8)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Numar_de_inventar]  CHAR (13)  NOT NULL,
    [Cod_material]       CHAR (20)  NOT NULL,
    [Alfa1]              CHAR (20)  NOT NULL,
    [Alfa2]              CHAR (20)  NOT NULL,
    [Val1]               FLOAT (53) NOT NULL,
    [Val2]               FLOAT (53) NOT NULL,
    [Data]               DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Numar_fisa]
    ON [dbo].[antecman]([Subunitate] ASC, [Comanda] ASC, [Val1] ASC, [Numar_fisa] ASC, [Numar_operatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_Cod]
    ON [dbo].[antecman]([Subunitate] ASC, [Comanda] ASC, [Cod_produs] ASC, [Cod_operatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Locm_operatie_produs]
    ON [dbo].[antecman]([Subunitate] ASC, [Loc_de_munca] ASC, [Numar_operatie] ASC, [Cod_produs] ASC);

