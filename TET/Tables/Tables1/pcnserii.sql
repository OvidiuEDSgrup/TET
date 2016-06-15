CREATE TABLE [dbo].[pcnserii] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Tip]           CHAR (2)   NOT NULL,
    [Contract]      CHAR (20)  NOT NULL,
    [Tert]          CHAR (13)  NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Cod]           CHAR (20)  NOT NULL,
    [Serie]         CHAR (20)  NOT NULL,
    [Cantitate]     FLOAT (53) NOT NULL,
    [Numar_pozitie] INT        NOT NULL,
    [Cant_aprob]    FLOAT (53) NOT NULL,
    [Cant_realiz]   FLOAT (53) NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Val3]          FLOAT (53) NOT NULL,
    [Alfa1]         CHAR (13)  NOT NULL,
    [Alfa2]         CHAR (13)  NOT NULL,
    [Alfa3]         CHAR (13)  NOT NULL,
    [Data_rez]      DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KPCS]
    ON [dbo].[pcnserii]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Data] ASC, [Cod] ASC, [Serie] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Serie]
    ON [dbo].[pcnserii]([Subunitate] ASC, [Serie] ASC);

