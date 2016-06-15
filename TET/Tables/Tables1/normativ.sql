CREATE TABLE [dbo].[normativ] (
    [Cod]          CHAR (20)  NOT NULL,
    [Denumire]     CHAR (30)  NOT NULL,
    [Tip_normativ] CHAR (1)   NOT NULL,
    [Dur_in_ani]   SMALLINT   NOT NULL,
    [Dur_in_UM]    FLOAT (53) NOT NULL,
    [UM_funct]     CHAR (3)   NOT NULL,
    [Necesar_RT]   FLOAT (53) NOT NULL,
    [Necesar_RC1]  FLOAT (53) NOT NULL,
    [Necesar_RC2]  FLOAT (53) NOT NULL,
    [Necesar_RK]   FLOAT (53) NOT NULL,
    [Zile_RT]      REAL       NOT NULL,
    [Zile_RC1]     REAL       NOT NULL,
    [Zile_RC2]     REAL       NOT NULL,
    [Zile_RK]      REAL       NOT NULL,
    [Procent_RT]   FLOAT (53) NOT NULL,
    [Procent_RC1]  FLOAT (53) NOT NULL,
    [Procent_RC2]  FLOAT (53) NOT NULL,
    [Procent_RK]   FLOAT (53) NOT NULL,
    [Caract_1]     CHAR (20)  NOT NULL,
    [Caract_2]     CHAR (20)  NOT NULL,
    [Caract_3]     CHAR (20)  NOT NULL,
    [Turatie]      REAL       NOT NULL,
    [Nr_mersuri]   REAL       NOT NULL,
    [Nr_masini]    REAL       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Normrep1]
    ON [dbo].[normativ]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Normrep2]
    ON [dbo].[normativ]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_normativ]
    ON [dbo].[normativ]([Tip_normativ] ASC, [Cod] ASC);

