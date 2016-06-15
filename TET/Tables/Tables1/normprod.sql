CREATE TABLE [dbo].[normprod] (
    [Cod_operatie]          CHAR (20)  NOT NULL,
    [Cod_materie_prima]     CHAR (20)  NOT NULL,
    [Cod_articol]           CHAR (20)  NOT NULL,
    [Cod_reper]             CHAR (20)  NOT NULL,
    [Grupa]                 CHAR (2)   NOT NULL,
    [Masina]                CHAR (13)  NOT NULL,
    [Categorie]             CHAR (4)   NOT NULL,
    [Grupa_fire_inferioara] REAL       NOT NULL,
    [Grupa_fire_superioara] REAL       NOT NULL,
    [Numar_muncitori]       REAL       NOT NULL,
    [Zona_de_deservire]     REAL       NOT NULL,
    [Lungime_urzeala]       REAL       NOT NULL,
    [Lungime_caneta]        REAL       NOT NULL,
    [Numar_mersuri]         REAL       NOT NULL,
    [Numar_fire_invelis]    REAL       NOT NULL,
    [Format]                CHAR (10)  NOT NULL,
    [Metraj]                CHAR (10)  NOT NULL,
    [Nivel]                 CHAR (20)  NOT NULL,
    [Fire_1]                REAL       NOT NULL,
    [Dublaj]                CHAR (10)  NOT NULL,
    [Faza]                  CHAR (10)  NOT NULL,
    [Nivel_2]               CHAR (20)  NOT NULL,
    [Fire_2]                REAL       NOT NULL,
    [Norma_de_productie]    FLOAT (53) NOT NULL,
    [Coeficient_tesut]      REAL       NOT NULL,
    [Operatie_antecalc]     BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[normprod]([Cod_operatie] ASC, [Cod_materie_prima] ASC, [Cod_articol] ASC, [Cod_reper] ASC, [Grupa] ASC, [Masina] ASC, [Grupa_fire_inferioara] ASC, [Zona_de_deservire] ASC, [Numar_mersuri] ASC, [Norma_de_productie] ASC);


GO
CREATE NONCLUSTERED INDEX [Grupa]
    ON [dbo].[normprod]([Cod_operatie] ASC, [Grupa] ASC);

