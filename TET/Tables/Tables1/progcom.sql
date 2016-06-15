CREATE TABLE [dbo].[progcom] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Comanda]       CHAR (13)  NOT NULL,
    [Cod]           CHAR (20)  NOT NULL,
    [Loc_munca]     CHAR (9)   NOT NULL,
    [Cantitate]     FLOAT (53) NOT NULL,
    [Valuta]        CHAR (3)   NOT NULL,
    [Pret]          FLOAT (53) NOT NULL,
    [Explicatii]    CHAR (50)  NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL,
    [Alfa1]         CHAR (13)  NOT NULL,
    [Alfa2]         CHAR (13)  NOT NULL,
    [Alfa3]         CHAR (13)  NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Val3]          FLOAT (53) NOT NULL,
    [Data_rez]      DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Progcom1]
    ON [dbo].[progcom]([Subunitate] ASC, [Data] ASC, [Comanda] ASC, [Cod] ASC, [Loc_munca] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Progcom2]
    ON [dbo].[progcom]([Subunitate] ASC, [Comanda] ASC, [Cod] ASC, [Data] ASC, [Loc_munca] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Progcom3]
    ON [dbo].[progcom]([Subunitate] ASC, [Loc_munca] ASC, [Data] ASC, [Comanda] ASC, [Cod] ASC);

