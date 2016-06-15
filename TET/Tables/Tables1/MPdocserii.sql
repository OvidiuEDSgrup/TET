CREATE TABLE [dbo].[MPdocserii] (
    [Subunitate]       CHAR (9)   NOT NULL,
    [Tip]              CHAR (2)   NOT NULL,
    [Numar]            CHAR (20)  NOT NULL,
    [Data]             DATETIME   NOT NULL,
    [Schimb]           FLOAT (53) NOT NULL,
    [Sarja]            FLOAT (53) NOT NULL,
    [Ordonare]         FLOAT (53) NOT NULL,
    [Gestiune]         CHAR (20)  NOT NULL,
    [Loc_munca]        CHAR (20)  NOT NULL,
    [Loc_munca_prim]   CHAR (20)  NOT NULL,
    [Utilaj]           CHAR (20)  NOT NULL,
    [Utilaj_prim]      CHAR (20)  NOT NULL,
    [Cod]              CHAR (20)  NOT NULL,
    [Serie]            CHAR (20)  NOT NULL,
    [De_fabricat]      FLOAT (53) NOT NULL,
    [Fabricat]         FLOAT (53) NOT NULL,
    [Stoc]             FLOAT (53) NOT NULL,
    [Predat]           FLOAT (53) NOT NULL,
    [Rebut]            FLOAT (53) NOT NULL,
    [Rebut_KG]         FLOAT (53) NOT NULL,
    [Preluat]          FLOAT (53) NOT NULL,
    [Alfa1]            CHAR (20)  NOT NULL,
    [Alfa2]            CHAR (20)  NOT NULL,
    [Alfa3]            CHAR (30)  NOT NULL,
    [Val1]             FLOAT (53) NOT NULL,
    [Val2]             FLOAT (53) NOT NULL,
    [Val3]             FLOAT (53) NOT NULL,
    [Tip_misc]         CHAR (20)  NOT NULL,
    [Nr_pozitie]       INT        NOT NULL,
    [Nr_pozitie_serie] INT        NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MPdocserii1]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Nr_pozitie] ASC, [Nr_pozitie_serie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii2]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Nr_pozitie] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii3]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Tip] ASC, [Cod] ASC, [Serie] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii4]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Tip] ASC, [Cod] ASC, [Serie] ASC, [Loc_munca_prim] ASC, [Utilaj_prim] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii5]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Cod] ASC, [Serie] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Tip] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii6]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Cod] ASC, [Serie] ASC, [Loc_munca_prim] ASC, [Utilaj_prim] ASC, [Tip] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii7]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Gestiune] ASC, [Cod] ASC, [Alfa1] ASC, [Nr_pozitie] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocserii8]
    ON [dbo].[MPdocserii]([Subunitate] ASC, [Gestiune] ASC, [Cod] ASC, [Serie] ASC, [Tip] ASC);

