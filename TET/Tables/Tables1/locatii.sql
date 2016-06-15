CREATE TABLE [dbo].[locatii] (
    [Cod_locatie]  CHAR (13)  NOT NULL,
    [Este_grup]    BIT        NOT NULL,
    [Cod_grup]     CHAR (13)  NOT NULL,
    [UM]           CHAR (3)   NOT NULL,
    [Capacitate]   FLOAT (53) NOT NULL,
    [Cod_gestiune] CHAR (9)   NOT NULL,
    [Incarcare]    BIT        NOT NULL,
    [Nivel]        SMALLINT   NOT NULL,
    [Descriere]    CHAR (30)  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Locatie]
    ON [dbo].[locatii]([Cod_gestiune] ASC, [Cod_locatie] ASC);

