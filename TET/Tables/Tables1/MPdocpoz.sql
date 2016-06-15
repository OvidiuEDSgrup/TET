CREATE TABLE [dbo].[MPdocpoz] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Numar]          CHAR (20)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Schimb]         FLOAT (53) NOT NULL,
    [Sarja]          FLOAT (53) NOT NULL,
    [Ordonare]       FLOAT (53) NOT NULL,
    [Gestiune]       CHAR (20)  NOT NULL,
    [Loc_munca]      CHAR (20)  NOT NULL,
    [Loc_munca_prim] CHAR (20)  NOT NULL,
    [Utilaj]         CHAR (20)  NOT NULL,
    [Utilaj_prim]    CHAR (20)  NOT NULL,
    [Comanda]        CHAR (20)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [De_fabricat]    FLOAT (53) NOT NULL,
    [Fabricat]       FLOAT (53) NOT NULL,
    [Stoc]           FLOAT (53) NOT NULL,
    [Predat]         FLOAT (53) NOT NULL,
    [Rebut]          FLOAT (53) NOT NULL,
    [Rebut_KG]       FLOAT (53) NOT NULL,
    [Preluat]        FLOAT (53) NOT NULL,
    [Pret]           FLOAT (53) NOT NULL,
    [Locatie]        CHAR (30)  NOT NULL,
    [Lot]            CHAR (20)  NOT NULL,
    [Data_expirarii] DATETIME   NOT NULL,
    [Tip_consum]     CHAR (20)  NOT NULL,
    [Nr_operatie]    FLOAT (53) NOT NULL,
    [Cod_operatie]   CHAR (20)  NOT NULL,
    [Ora_inceput]    CHAR (6)   NOT NULL,
    [Ora_sfarsit]    CHAR (6)   NOT NULL,
    [Alfa1]          CHAR (20)  NOT NULL,
    [Alfa2]          CHAR (30)  NOT NULL,
    [Alfa3]          CHAR (30)  NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Val3]           FLOAT (53) NOT NULL,
    [Tip_misc]       CHAR (20)  NOT NULL,
    [Nr_pozitie]     INT        NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Jurnal]         CHAR (20)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MPdocpoz2]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Nr_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdocpoz1]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Gestiune] ASC, [Cod] ASC, [Alfa1] ASC, [Pret] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz3]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Cod] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Tip] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz4]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Cod] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz5]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Comanda] ASC, [Numar] ASC, [Nr_operatie] ASC, [Data] ASC, [Ora_inceput] ASC, [Loc_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz6]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Comanda] ASC, [Cod] ASC, [Nr_operatie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz7]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Ora_inceput] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdocpoz8]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Comanda] ASC, [Loc_munca] ASC, [Cod] ASC, [Nr_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdocpoz9]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Comanda] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz10]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Cod] ASC, [Loc_munca_prim] ASC, [Utilaj_prim] ASC, [Tip] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz11]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Cod] ASC, [Loc_munca_prim] ASC, [Utilaj_prim] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz12]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Comanda] ASC, [Cod] ASC, [Data] ASC, [Numar] ASC, [Loc_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz13]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Ora_inceput] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz14]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Loc_munca] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz15]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Ordonare] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdocpoz16]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Jurnal] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz17]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Alfa2] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocpoz18]
    ON [dbo].[MPdocpoz]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Alfa3] ASC);

