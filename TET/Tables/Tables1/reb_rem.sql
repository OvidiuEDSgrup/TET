CREATE TABLE [dbo].[reb_rem] (
    [Subunitate]                CHAR (9)   NOT NULL,
    [Tip]                       CHAR (2)   NOT NULL,
    [Numar]                     CHAR (8)   NOT NULL,
    [Data]                      DATETIME   NOT NULL,
    [Numar_pozitie]             INT        NOT NULL,
    [Obs_derog_dupa]            CHAR (200) NOT NULL,
    [Necesitate_remaniere]      CHAR (30)  NOT NULL,
    [Descriere_rebut]           CHAR (30)  NOT NULL,
    [Cost_manopera_rebut]       FLOAT (53) NOT NULL,
    [Cost_materiale_rebut]      FLOAT (53) NOT NULL,
    [Cheltuieli_sectie_rebut]   FLOAT (53) NOT NULL,
    [Destinatia_mat_recuperat]  CHAR (10)  NOT NULL,
    [Cantitate_mat_recuperat]   FLOAT (53) NOT NULL,
    [Pret_unitar_mat_recuperat] FLOAT (53) NOT NULL,
    [Data_relansare]            DATETIME   NOT NULL,
    [Cantitate_relansare]       FLOAT (53) NOT NULL,
    [Termen_relansare]          CHAR (10)  NOT NULL,
    [Cauza_rebut]               CHAR (1)   NOT NULL,
    [Tip_pierdere]              CHAR (1)   NOT NULL,
    [Cost_manopera_2]           FLOAT (53) NOT NULL,
    [Cost_materiale_2]          FLOAT (53) NOT NULL,
    [Cheltuieli_sectie_2]       FLOAT (53) NOT NULL,
    [Cost_manopera_3]           FLOAT (53) NOT NULL,
    [Cost_materiale_3]          FLOAT (53) NOT NULL,
    [Cheltuieli_sectie_3]       FLOAT (53) NOT NULL,
    [Denumire_operatie1]        CHAR (10)  NOT NULL,
    [Loc_de_lucru1]             CHAR (10)  NOT NULL,
    [Timp_manopera1]            CHAR (10)  NOT NULL,
    [Denumire_operatie2]        CHAR (10)  NOT NULL,
    [Loc_de_lucru2]             CHAR (10)  NOT NULL,
    [Timp_manopera2]            CHAR (10)  NOT NULL,
    [Denumire_operatie3]        CHAR (10)  NOT NULL,
    [Loc_de_lucru3]             CHAR (10)  NOT NULL,
    [Timp_manopera3]            CHAR (10)  NOT NULL,
    [Denumire_operatie4]        CHAR (10)  NOT NULL,
    [Loc_de_lucru4]             CHAR (10)  NOT NULL,
    [Timp_manopera4]            CHAR (10)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CalitRM]
    ON [dbo].[reb_rem]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);

