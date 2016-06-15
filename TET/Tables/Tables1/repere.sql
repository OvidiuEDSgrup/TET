CREATE TABLE [dbo].[repere] (
    [Cod_reper]            CHAR (20)  NOT NULL,
    [Denumire]             CHAR (80)  NOT NULL,
    [Tip_reper]            CHAR (1)   NOT NULL,
    [UM]                   CHAR (3)   NOT NULL,
    [Lungime_net]          FLOAT (53) NOT NULL,
    [Latime_diametru_net]  FLOAT (53) NOT NULL,
    [Inaltime_net]         FLOAT (53) NOT NULL,
    [Lungime_brut]         FLOAT (53) NOT NULL,
    [Latime_diametru_brut] FLOAT (53) NOT NULL,
    [Inaltime_brut]        FLOAT (53) NOT NULL,
    [Cod_desen]            CHAR (20)  NOT NULL,
    [Masa_neta]            FLOAT (53) NOT NULL,
    [Masa_bruta]           FLOAT (53) NOT NULL,
    [Pret]                 FLOAT (53) NOT NULL,
    [Utilizator]           CHAR (10)  NOT NULL,
    [Data_reper]           DATETIME   NOT NULL,
    [Data_normare]         DATETIME   NOT NULL,
    [Rezerva]              CHAR (100) NOT NULL,
    [Forma_finala]         CHAR (50)  NOT NULL,
    [Material_abraziv]     CHAR (50)  NOT NULL,
    [Granulatie]           FLOAT (53) NOT NULL,
    [Duritate]             CHAR (20)  NOT NULL,
    [Structura]            FLOAT (53) NOT NULL,
    [Tip_liant]            CHAR (20)  NOT NULL,
    [Impregnare]           CHAR (20)  NOT NULL,
    [Viteza_perif]         FLOAT (53) NOT NULL,
    [Alfa1]                CHAR (20)  NOT NULL,
    [Alfa2]                CHAR (20)  NOT NULL,
    [Alfa3]                CHAR (20)  NOT NULL,
    [Alfa4]                CHAR (20)  NOT NULL,
    [Alfa5]                CHAR (20)  NOT NULL,
    [Val1]                 FLOAT (53) NOT NULL,
    [Val2]                 FLOAT (53) NOT NULL,
    [Val3]                 FLOAT (53) NOT NULL,
    [Val4]                 FLOAT (53) NOT NULL,
    [Val5]                 FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_reper]
    ON [dbo].[repere]([Cod_reper] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[repere]([Denumire] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip_reper]
    ON [dbo].[repere]([Tip_reper] ASC, [Cod_reper] ASC);


GO
CREATE NONCLUSTERED INDEX [Data_reper]
    ON [dbo].[repere]([Data_reper] ASC);


GO
CREATE NONCLUSTERED INDEX [Data_normare]
    ON [dbo].[repere]([Data_normare] ASC);

