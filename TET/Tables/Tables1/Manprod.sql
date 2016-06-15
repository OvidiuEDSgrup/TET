CREATE TABLE [dbo].[Manprod] (
    [Data]              DATETIME   NOT NULL,
    [Cod_produs]        CHAR (20)  NOT NULL,
    [Cod_reper]         CHAR (20)  NOT NULL,
    [Cod_operatie]      CHAR (20)  NOT NULL,
    [Cod_material]      CHAR (20)  NOT NULL,
    [Loc_de_munca]      CHAR (9)   NOT NULL,
    [Grupa]             CHAR (2)   NOT NULL,
    [Tip_utilaj]        CHAR (13)  NOT NULL,
    [Categoria]         CHAR (4)   NOT NULL,
    [UM]                CHAR (3)   NOT NULL,
    [Lungime_urzeala]   REAL       NOT NULL,
    [Consum_pe_UM]      FLOAT (53) NOT NULL,
    [Norma_masina]      FLOAT (53) NOT NULL,
    [Numar_muncitori]   REAL       NOT NULL,
    [Zona_de_deservire] REAL       NOT NULL,
    [Norma_om]          FLOAT (53) NOT NULL,
    [Tarif_unitar]      FLOAT (53) NOT NULL,
    [Manopera_ore_om]   FLOAT (53) NOT NULL,
    [Manopera_lei]      FLOAT (53) NOT NULL,
    [Numar_fire]        REAL       NOT NULL,
    [Coeficient_sectie] FLOAT (53) NOT NULL,
    [Coeficient_regie]  FLOAT (53) NOT NULL,
    [Salar_orar]        FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Manprod]([Data] ASC, [Cod_produs] ASC, [Cod_reper] ASC, [Cod_operatie] ASC, [Tip_utilaj] ASC, [Norma_om] ASC);


GO
CREATE NONCLUSTERED INDEX [Loc_de_munca]
    ON [dbo].[Manprod]([Data] ASC, [Cod_produs] ASC, [Cod_operatie] ASC, [Cod_material] ASC);

