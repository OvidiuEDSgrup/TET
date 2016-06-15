CREATE TABLE [dbo].[istPers] (
    [Data]                          DATETIME     NOT NULL,
    [Marca]                         CHAR (6)     NOT NULL,
    [Nume]                          CHAR (50)    NOT NULL,
    [Cod_functie]                   CHAR (6)     NOT NULL,
    [Loc_de_munca]                  CHAR (9)     NOT NULL,
    [Categoria_salarizare]          CHAR (4)     NOT NULL,
    [Grupa_de_munca]                CHAR (1)     NOT NULL,
    [Tip_salarizare]                CHAR (1)     NOT NULL,
    [Tip_impozitare]                CHAR (1)     NOT NULL,
    [Salar_de_incadrare]            FLOAT (53)   NOT NULL,
    [Salar_de_baza]                 FLOAT (53)   NOT NULL,
    [Indemnizatia_de_conducere]     FLOAT (53)   NOT NULL,
    [Spor_vechime]                  REAL         NOT NULL,
    [Spor_de_noapte]                REAL         NOT NULL,
    [Spor_sistematic_peste_program] REAL         NOT NULL,
    [Spor_de_functie_suplimentara]  FLOAT (53)   NOT NULL,
    [Spor_specific]                 FLOAT (53)   NOT NULL,
    [Spor_conditii_1]               FLOAT (53)   NOT NULL,
    [Spor_conditii_2]               FLOAT (53)   NOT NULL,
    [Spor_conditii_3]               FLOAT (53)   NOT NULL,
    [Spor_conditii_4]               FLOAT (53)   NOT NULL,
    [Spor_conditii_5]               FLOAT (53)   NOT NULL,
    [Spor_conditii_6]               FLOAT (53)   NOT NULL,
    [Salar_lunar_de_baza]           FLOAT (53)   NOT NULL,
    [Localitate]                    CHAR (30)    NOT NULL,
    [Judet]                         CHAR (15)    NOT NULL,
    [Strada]                        CHAR (25)    NOT NULL,
    [Numar]                         CHAR (5)     NOT NULL,
    [Cod_postal]                    INT          NOT NULL,
    [Bloc]                          CHAR (10)    NOT NULL,
    [Scara]                         CHAR (2)     NOT NULL,
    [Etaj]                          CHAR (2)     NOT NULL,
    [Apartament]                    CHAR (5)     NOT NULL,
    [Sector]                        SMALLINT     NOT NULL,
    [Mod_angajare]                  CHAR (1)     NOT NULL,
    [Data_plec]                     DATETIME     NOT NULL,
    [Tip_colab]                     CHAR (3)     NOT NULL,
    [grad_invalid]                  CHAR (1)     NOT NULL,
    [coef_invalid]                  REAL         NOT NULL,
    [alte_surse]                    BIT          NOT NULL,
    [Vechime_totala]                DATETIME     NULL,
    [detalii]                       XML          NULL,
    [Activitate]                    VARCHAR (10) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[istPers]([Data] ASC, [Marca] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Marca_Data]
    ON [dbo].[istPers]([Marca] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Nume]
    ON [dbo].[istPers]([Nume] ASC);

