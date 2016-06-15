CREATE TABLE [dbo].[pretaclc] (
    [Reper]           CHAR (20)  NOT NULL,
    [Data]            DATETIME   NOT NULL,
    [Nr_acalc]        SMALLINT   NOT NULL,
    [Tip]             CHAR (1)   NOT NULL,
    [Numar]           SMALLINT   NOT NULL,
    [Cod]             CHAR (20)  NOT NULL,
    [Loc_munca]       CHAR (9)   NOT NULL,
    [Consum_specific] FLOAT (53) NOT NULL,
    [Pret]            FLOAT (53) NOT NULL,
    [Utilizator]      CHAR (10)  NOT NULL,
    [Data_operarii]   DATETIME   NOT NULL,
    [Ora_operarii]    CHAR (6)   NOT NULL,
    [Val1]            FLOAT (53) NOT NULL,
    [Val2]            FLOAT (53) NOT NULL,
    [Val3]            FLOAT (53) NOT NULL,
    [Alfa1]           CHAR (13)  NOT NULL,
    [Alfa2]           CHAR (13)  NOT NULL,
    [Data_rez]        DATETIME   NOT NULL,
    [Denumire]        CHAR (40)  NOT NULL,
    [Alfa3]           CHAR (20)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pretac]
    ON [dbo].[pretaclc]([Reper] ASC, [Data] ASC, [Nr_acalc] ASC, [Tip] ASC, [Numar] ASC, [Cod] ASC, [Loc_munca] ASC);

