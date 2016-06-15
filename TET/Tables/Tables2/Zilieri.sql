CREATE TABLE [dbo].[Zilieri] (
    [Marca]                CHAR (6)   NOT NULL,
    [Nume]                 CHAR (50)  NOT NULL,
    [Cod_functie]          CHAR (6)   NOT NULL,
    [Loc_de_munca]         CHAR (9)   NOT NULL,
    [Comanda]              CHAR (20)  NOT NULL,
    [Salar_de_incadrare]   FLOAT (53) NOT NULL,
    [Tip_salar_orar]       CHAR (1)   NOT NULL,
    [Salar_orar]           FLOAT (53) NOT NULL,
    [Data_angajarii]       DATETIME   NOT NULL,
    [Plecat]               BIT        NOT NULL,
    [Data_plecarii]        DATETIME   NOT NULL,
    [Banca]                CHAR (25)  NOT NULL,
    [Cont_in_banca]        CHAR (25)  NOT NULL,
    [Cod_numeric_personal] CHAR (13)  NOT NULL,
    [Data_nasterii]        DATETIME   NOT NULL,
    [Sex]                  BIT        NOT NULL,
    [Buletin]              CHAR (30)  NOT NULL,
    [Data_eliberarii]      DATETIME   NOT NULL,
    [Localitate]           CHAR (30)  NOT NULL,
    [Judet]                CHAR (15)  NOT NULL,
    [Strada]               CHAR (25)  NOT NULL,
    [Numar]                CHAR (5)   NOT NULL,
    [Cod_postal]           INT        NOT NULL,
    [Bloc]                 CHAR (10)  NOT NULL,
    [Scara]                CHAR (2)   NOT NULL,
    [Etaj]                 CHAR (2)   NOT NULL,
    [Apartament]           CHAR (5)   NOT NULL,
    [Sector]               SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Marca]
    ON [dbo].[Zilieri]([Marca] ASC);


GO
CREATE NONCLUSTERED INDEX [Nume]
    ON [dbo].[Zilieri]([Nume] ASC);

