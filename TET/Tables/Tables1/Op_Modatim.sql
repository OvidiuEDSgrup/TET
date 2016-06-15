CREATE TABLE [dbo].[Op_Modatim] (
    [Hostid]   CHAR (20)  NOT NULL,
    [Cod]      CHAR (20)  NOT NULL,
    [Denumire] CHAR (100) NOT NULL,
    [Logic]    BIT        NOT NULL,
    [Cant]     FLOAT (53) NOT NULL,
    [Norma]    FLOAT (53) NOT NULL,
    [Numar]    INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Op_Modatim]([Hostid] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_pozitie]
    ON [dbo].[Op_Modatim]([Hostid] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[Op_Modatim]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[Op_Modatim]([Hostid] ASC, [Denumire] ASC);

