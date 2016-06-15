CREATE TABLE [dbo].[MPdocndpoz] (
    [Tip]            CHAR (2)   NOT NULL,
    [Numar]          CHAR (20)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Schimb]         FLOAT (53) NOT NULL,
    [Sarja]          FLOAT (53) NOT NULL,
    [Ordonare]       FLOAT (53) NOT NULL,
    [Loc_munca]      CHAR (20)  NOT NULL,
    [Utilaj]         CHAR (20)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [Intrari]        FLOAT (53) NOT NULL,
    [Normat]         FLOAT (53) NOT NULL,
    [Efectiv]        FLOAT (53) NOT NULL,
    [Stoc]           FLOAT (53) NOT NULL,
    [Nr_pozitie]     INT        NOT NULL,
    [Nr_pozitie_DN]  INT        NOT NULL,
    [Gestiune]       CHAR (20)  NOT NULL,
    [Comanda]        CHAR (20)  NOT NULL,
    [Cod_produs]     CHAR (20)  NOT NULL,
    [Alfa1]          CHAR (20)  NOT NULL,
    [Lot]            CHAR (20)  NOT NULL,
    [Locatie]        CHAR (30)  NOT NULL,
    [Repartizat]     FLOAT (53) NOT NULL,
    [Abateri]        FLOAT (53) NOT NULL,
    [Cod_parinte]    CHAR (20)  NOT NULL,
    [Cod_inlocuit]   CHAR (20)  NOT NULL,
    [Nr_mat]         FLOAT (53) NOT NULL,
    [Alfa2]          CHAR (30)  NOT NULL,
    [Specific]       FLOAT (53) NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Pret]           FLOAT (53) NOT NULL,
    [Data_expirarii] DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MPdocndpoz9]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Cod] ASC, [Data] DESC, [Schimb] DESC, [Sarja] DESC, [Nr_pozitie] DESC, [Numar] DESC, [Gestiune] ASC, [Cod_parinte] ASC, [Cod_inlocuit] ASC, [Nr_mat] ASC, [Alfa2] ASC, [Nr_pozitie_DN] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdocndpoz1]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Data] ASC, [Numar] ASC, [Nr_pozitie] ASC, [Nr_pozitie_DN] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz2]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Numar] ASC, [Data] ASC, [Cod] ASC, [Gestiune] ASC, [Alfa2] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz3]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Numar] ASC, [Data] ASC, [Comanda] ASC, [Cod_produs] ASC, [Cod] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz4]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Numar] ASC, [Data] ASC, [Cod_produs] ASC, [Comanda] ASC, [Cod] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz5]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Cod] ASC, [Alfa2] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz6]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Cod] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz7]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Loc_munca] ASC, [Cod] ASC, [Alfa2] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndpoz8]
    ON [dbo].[MPdocndpoz]([Tip] ASC, [Loc_munca] ASC, [Cod] ASC, [Ordonare] ASC);

