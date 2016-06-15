CREATE TABLE [dbo].[FisaTehn] (
    [Terminal]            REAL       NOT NULL,
    [Cod_produs]          CHAR (20)  NOT NULL,
    [Cod_reper]           CHAR (20)  NOT NULL,
    [Cod_operatie]        CHAR (20)  NOT NULL,
    [Cod_material]        CHAR (20)  NOT NULL,
    [Loc_de_munca]        CHAR (9)   NOT NULL,
    [Tip_utilaj]          CHAR (13)  NOT NULL,
    [Categoria]           CHAR (4)   NOT NULL,
    [UM]                  CHAR (3)   NOT NULL,
    [Lungime_urzeala]     REAL       NOT NULL,
    [Consum_pe_UM]        FLOAT (53) NOT NULL,
    [Numar_fire]          REAL       NOT NULL,
    [Numar_fire_rasucire] INT        NOT NULL,
    [Numar_operatie]      REAL       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[FisaTehn]([Terminal] ASC, [Cod_produs] ASC, [Cod_reper] ASC, [Cod_operatie] ASC, [Loc_de_munca] ASC, [Tip_utilaj] ASC, [Numar_operatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Loc_de_munca]
    ON [dbo].[FisaTehn]([Terminal] ASC, [Cod_produs] ASC, [Cod_reper] ASC, [Cod_operatie] ASC, [Loc_de_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_fisa]
    ON [dbo].[FisaTehn]([Terminal] ASC, [Cod_produs] ASC, [Cod_operatie] ASC, [Cod_material] ASC);

