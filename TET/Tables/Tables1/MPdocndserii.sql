CREATE TABLE [dbo].[MPdocndserii] (
    [Tip]              CHAR (2)   NOT NULL,
    [Numar]            CHAR (20)  NOT NULL,
    [Data]             DATETIME   NOT NULL,
    [Schimb]           FLOAT (53) NOT NULL,
    [Sarja]            FLOAT (53) NOT NULL,
    [Ordonare]         FLOAT (53) NOT NULL,
    [Loc_munca]        CHAR (20)  NOT NULL,
    [Utilaj]           CHAR (20)  NOT NULL,
    [Cod]              CHAR (20)  NOT NULL,
    [Intrari]          FLOAT (53) NOT NULL,
    [Normat]           FLOAT (53) NOT NULL,
    [Efectiv]          FLOAT (53) NOT NULL,
    [Stoc]             FLOAT (53) NOT NULL,
    [Nr_pozitie]       INT        NOT NULL,
    [Nr_pozitie_DN]    INT        NOT NULL,
    [Gestiune]         CHAR (20)  NOT NULL,
    [Alfa1]            CHAR (20)  NOT NULL,
    [Alfa2]            CHAR (30)  NOT NULL,
    [Alfa3]            CHAR (20)  NOT NULL,
    [Alfa4]            CHAR (20)  NOT NULL,
    [Alfa5]            CHAR (20)  NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL,
    [Val1]             FLOAT (53) NOT NULL,
    [Val2]             FLOAT (53) NOT NULL,
    [Val3]             FLOAT (53) NOT NULL,
    [Val4]             FLOAT (53) NOT NULL,
    [Val5]             FLOAT (53) NOT NULL,
    [Serie]            CHAR (30)  NOT NULL,
    [Nr_pozitie_serie] INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MPdocndserii9]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Cod] ASC, [Data] DESC, [Schimb] DESC, [Sarja] DESC, [Nr_pozitie] DESC, [Numar] DESC, [Gestiune] ASC, [Serie] ASC, [Nr_pozitie_DN] ASC, [Nr_pozitie_serie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdocndserii1]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Data] ASC, [Numar] ASC, [Nr_pozitie] ASC, [Nr_pozitie_DN] ASC, [Nr_pozitie_serie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii2]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Numar] ASC, [Data] ASC, [Cod] ASC, [Gestiune] ASC, [Serie] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii3]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Numar] ASC, [Data] ASC, [Cod] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii4]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Numar] ASC, [Data] ASC, [Nr_pozitie] ASC, [Nr_pozitie_DN] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii5]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Cod] ASC, [Serie] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii6]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Cod] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii7]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Loc_munca] ASC, [Cod] ASC, [Serie] ASC, [Ordonare] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdocndserii8]
    ON [dbo].[MPdocndserii]([Tip] ASC, [Loc_munca] ASC, [Cod] ASC, [Ordonare] ASC);

