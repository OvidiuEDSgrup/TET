CREATE TABLE [dbo].[IstOpRep] (
    [Reper]                   CHAR (20)  NOT NULL,
    [Pozitie]                 SMALLINT   NOT NULL,
    [Data]                    DATETIME   NOT NULL,
    [Ora]                     CHAR (6)   NOT NULL,
    [Utilizator]              CHAR (10)  NOT NULL,
    [Operatie]                CHAR (20)  NOT NULL,
    [Timp_anterior]           REAL       NOT NULL,
    [Timp_nou]                REAL       NOT NULL,
    [Stare]                   SMALLINT   NOT NULL,
    [Faza]                    SMALLINT   NOT NULL,
    [Subfaza]                 SMALLINT   NOT NULL,
    [Cant]                    FLOAT (53) NOT NULL,
    [Utilaj]                  CHAR (13)  NOT NULL,
    [Marime]                  CHAR (9)   NOT NULL,
    [Categoria_de_salarizare] CHAR (4)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[IstOpRep]([Reper] ASC, [Pozitie] ASC, [Data] ASC, [Ora] ASC, [Utilizator] ASC);

