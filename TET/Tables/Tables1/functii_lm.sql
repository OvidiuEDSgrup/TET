CREATE TABLE [dbo].[functii_lm] (
    [Data]               DATETIME   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Cod_functie]        CHAR (6)   NOT NULL,
    [Denumire]           CHAR (50)  NOT NULL,
    [Tip_personal]       CHAR (1)   NOT NULL,
    [Salar_de_incadrare] FLOAT (53) NOT NULL,
    [Numar_posturi]      FLOAT (53) NOT NULL,
    [Regim_de_lucru]     FLOAT (53) NOT NULL,
    [Pozitie_stat]       INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_lm_functie]
    ON [dbo].[functii_lm]([Data] ASC, [Loc_de_munca] ASC, [Cod_functie] ASC);

