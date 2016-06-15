CREATE TABLE [dbo].[textpozdoc] (
    [Subunitate]      CHAR (9)    NOT NULL,
    [Tip]             CHAR (2)    NOT NULL,
    [Numar]           CHAR (8)    NOT NULL,
    [Data]            DATETIME    NOT NULL,
    [Numar_pozitie]   INT         NOT NULL,
    [Explicatii]      CHAR (3000) NOT NULL,
    [Tara_de_origine] CHAR (3)    NOT NULL,
    [Alfa1]           CHAR (30)   NOT NULL,
    [Alfa2]           CHAR (30)   NOT NULL,
    [Alfa3]           CHAR (200)  NOT NULL,
    [Val1]            FLOAT (53)  NOT NULL,
    [Val2]            FLOAT (53)  NOT NULL,
    [Val3]            FLOAT (53)  NOT NULL,
    [Data1]           DATETIME    NOT NULL,
    [Data2]           DATETIME    NOT NULL,
    [Data3]           DATETIME    NOT NULL,
    [Logic]           BIT         NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[textpozdoc]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);

