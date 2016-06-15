CREATE TABLE [dbo].[localizari] (
    [Cod]         CHAR (20)  NOT NULL,
    [Denumire]    CHAR (100) NOT NULL,
    [Tip]         CHAR (50)  NOT NULL,
    [Judet]       CHAR (50)  NOT NULL,
    [Localitate]  CHAR (50)  NOT NULL,
    [Adresa]      CHAR (100) NOT NULL,
    [Responsabil] CHAR (30)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[localizari]([Cod] ASC);

