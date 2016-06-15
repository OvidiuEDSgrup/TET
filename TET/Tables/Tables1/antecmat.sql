CREATE TABLE [dbo].[antecmat] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Comanda]            CHAR (20)  NOT NULL,
    [Cod_produs]         CHAR (20)  NOT NULL,
    [Tip_reper_mat]      BINARY (1) NOT NULL,
    [Cod_tata]           CHAR (20)  NOT NULL,
    [Cod_material]       CHAR (20)  NOT NULL,
    [Cod_inlocuit]       CHAR (20)  NOT NULL,
    [Cantitate_necesara] FLOAT (53) NOT NULL,
    [Pret]               FLOAT (53) NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Numar_fisa]         CHAR (8)   NOT NULL,
    [Gestiune]           CHAR (9)   NOT NULL,
    [Alfa1]              CHAR (20)  NOT NULL,
    [Alfa2]              CHAR (20)  NOT NULL,
    [Val1]               FLOAT (53) NOT NULL,
    [Val2]               FLOAT (53) NOT NULL,
    [Data]               DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[antecmat]([Subunitate] ASC, [Comanda] ASC, [Val1] ASC, [Cod_tata] ASC, [Cod_material] ASC, [Numar_fisa] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_Tip_Cod]
    ON [dbo].[antecmat]([Subunitate] ASC, [Comanda] ASC, [Cod_produs] ASC, [Tip_reper_mat] ASC, [Cod_material] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Pe_locm]
    ON [dbo].[antecmat]([Subunitate] ASC, [Comanda] ASC, [Val1] ASC, [Cod_tata] ASC, [Loc_de_munca] ASC, [Tip_reper_mat] ASC, [Cod_material] ASC, [Numar_fisa] ASC);

