CREATE TABLE [dbo].[rezervari] (
    [Gestiune]   CHAR (9)   NOT NULL,
    [Cod]        CHAR (20)  NOT NULL,
    [Utilizator] CHAR (10)  NOT NULL,
    [Data]       DATETIME   NOT NULL,
    [Tert]       CHAR (13)  NOT NULL,
    [Cantitate]  FLOAT (53) NOT NULL,
    [Explicatii] CHAR (50)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [RezPrincipal]
    ON [dbo].[rezervari]([Gestiune] ASC, [Cod] ASC, [Utilizator] ASC, [Data] ASC, [Tert] ASC);

