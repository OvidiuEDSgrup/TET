CREATE TABLE [dbo].[realrepp] (
    [Numar_fisa]               CHAR (8)   NOT NULL,
    [Data]                     DATETIME   NOT NULL,
    [Schimb]                   CHAR (1)   NOT NULL,
    [Comanda]                  CHAR (13)  NOT NULL,
    [Cod_reper]                CHAR (20)  NOT NULL,
    [Numar_operatie]           SMALLINT   NOT NULL,
    [Cod_operatie]             CHAR (20)  NOT NULL,
    [Loc_de_munca]             CHAR (9)   NOT NULL,
    [Tip_utilaj]               CHAR (13)  NOT NULL,
    [Cod_material]             CHAR (20)  NOT NULL,
    [Cod_material_1]           CHAR (20)  NOT NULL,
    [Cod_material_2]           CHAR (20)  NOT NULL,
    [Numar_fire]               REAL       NOT NULL,
    [Numar_fire_nivel_1]       REAL       NOT NULL,
    [Numar_fire_nivel_2]       REAL       NOT NULL,
    [Numar_masina]             CHAR (13)  NOT NULL,
    [Grupa]                    CHAR (3)   NOT NULL,
    [Norma_de_productie]       FLOAT (53) NOT NULL,
    [Tarif_unitar]             FLOAT (53) NOT NULL,
    [Mii_batai]                REAL       NOT NULL,
    [Contor_1]                 FLOAT (53) NOT NULL,
    [Contor_2]                 FLOAT (53) NOT NULL,
    [Coeficient_tesut]         REAL       NOT NULL,
    [Numar_mersuri]            REAL       NOT NULL,
    [Cantitate_echivalenta]    FLOAT (53) NOT NULL,
    [Cantitate]                FLOAT (53) NOT NULL,
    [Culoare]                  CHAR (20)  NOT NULL,
    [Lungime_caneta]           REAL       NOT NULL,
    [Dublaj]                   CHAR (10)  NOT NULL,
    [Um]                       CHAR (3)   NOT NULL,
    [Numar_fuse]               REAL       NOT NULL,
    [Format]                   CHAR (10)  NOT NULL,
    [Faza]                     CHAR (10)  NOT NULL,
    [Marca_1]                  CHAR (6)   NOT NULL,
    [Marca_2]                  CHAR (6)   NOT NULL,
    [Total_ore]                SMALLINT   NOT NULL,
    [Ore_acord]                SMALLINT   NOT NULL,
    [Ore_regie]                SMALLINT   NOT NULL,
    [Ore_75_O]                 SMALLINT   NOT NULL,
    [Ore_75_C]                 SMALLINT   NOT NULL,
    [Ore_75_D]                 SMALLINT   NOT NULL,
    [Ore_100]                  SMALLINT   NOT NULL,
    [Numar_pentru_intreruperi] REAL       NOT NULL,
    [Ore_stationare_D]         SMALLINT   NOT NULL,
    [Ore_stationare_R]         SMALLINT   NOT NULL,
    [Ore_stationare_F]         SMALLINT   NOT NULL,
    [Ore_stationare_X]         SMALLINT   NOT NULL,
    [Ore_stationare_I]         SMALLINT   NOT NULL,
    [Numar_pozitie]            INT        NOT NULL,
    [Data_op]                  DATETIME   NOT NULL,
    [Utilizator]               CHAR (10)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[realrepp]([Data] ASC, [Schimb] ASC, [Numar_fisa] ASC, [Cod_reper] ASC, [Loc_de_munca] ASC, [Numar_masina] ASC, [Marca_1] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda]
    ON [dbo].[realrepp]([Comanda] ASC, [Numar_masina] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_fisa]
    ON [dbo].[realrepp]([Numar_pozitie] ASC, [Numar_fisa] ASC, [Data] ASC, [Schimb] ASC);


GO
CREATE NONCLUSTERED INDEX [Schimb]
    ON [dbo].[realrepp]([Schimb] ASC, [Data] ASC, [Comanda] ASC);

