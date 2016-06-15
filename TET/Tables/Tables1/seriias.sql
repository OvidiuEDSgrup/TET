CREATE TABLE [dbo].[seriias] (
    [Subunitate]   CHAR (9)  NOT NULL,
    [Tip_gestiune] CHAR (1)  NOT NULL,
    [Gestiune]     CHAR (9)  NOT NULL,
    [Cod]          CHAR (20) NOT NULL,
    [Cod_intrare]  CHAR (13) NOT NULL,
    [Serie]        CHAR (20) NOT NULL,
    [Proprietate]  CHAR (13) NOT NULL,
    [Serieas]      CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KSAsoc]
    ON [dbo].[seriias]([Subunitate] ASC, [Tip_gestiune] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Serie] ASC, [Serieas] ASC);


GO
CREATE NONCLUSTERED INDEX [Proprietate]
    ON [dbo].[seriias]([Proprietate] ASC);

