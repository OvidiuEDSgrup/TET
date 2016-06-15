CREATE TABLE [dbo].[OpModatim] (
    [Terminal] SMALLINT   NOT NULL,
    [Cod]      CHAR (20)  NOT NULL,
    [Denumire] CHAR (100) NOT NULL,
    [Logic]    BIT        NOT NULL,
    [Cant]     FLOAT (53) NOT NULL,
    [Norma]    FLOAT (53) NOT NULL,
    [Numar]    INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[OpModatim]([Terminal] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_pozitie]
    ON [dbo].[OpModatim]([Terminal] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[OpModatim]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[OpModatim]([Terminal] ASC, [Denumire] ASC);

