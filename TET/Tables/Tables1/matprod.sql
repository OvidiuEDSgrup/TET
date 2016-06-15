CREATE TABLE [dbo].[matprod] (
    [Utilizator]      CHAR (10)  NOT NULL,
    [Cod_produs]      CHAR (20)  NOT NULL,
    [Cod_reper]       CHAR (20)  NOT NULL,
    [Cod_material]    CHAR (20)  NOT NULL,
    [Cod_operatie]    CHAR (20)  NOT NULL,
    [Tip_material]    CHAR (1)   NOT NULL,
    [Consum_specific] FLOAT (53) NOT NULL,
    [Cod_inlocuit]    CHAR (20)  NOT NULL,
    [Loc_de_munca]    CHAR (9)   NOT NULL,
    [Cantitate_neta]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Structura]
    ON [dbo].[matprod]([Utilizator] ASC, [Cod_produs] ASC, [Cod_reper] ASC, [Cod_material] ASC, [Cod_operatie] ASC, [Loc_de_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [Inlocuitor]
    ON [dbo].[matprod]([Utilizator] ASC, [Cod_reper] ASC, [Cod_inlocuit] ASC);

