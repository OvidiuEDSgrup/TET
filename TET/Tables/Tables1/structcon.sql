CREATE TABLE [dbo].[structcon] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Tip]        CHAR (2)   NOT NULL,
    [Contract]   CHAR (20)  NOT NULL,
    [Tert]       CHAR (13)  NOT NULL,
    [Data]       DATETIME   NOT NULL,
    [Pozitie]    INT        NOT NULL,
    [Parinte]    INT        NOT NULL,
    [Text]       CHAR (200) NOT NULL,
    [Cantitate]  FLOAT (53) NOT NULL,
    [Pret]       FLOAT (53) NOT NULL,
    [Valoare]    FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[structcon]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Data] ASC, [Pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Cautare_fii]
    ON [dbo].[structcon]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Data] ASC, [Parinte] ASC);

