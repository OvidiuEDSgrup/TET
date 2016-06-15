CREATE TABLE [dbo].[pdserii] (
    [Subunitate]          CHAR (9)   NOT NULL,
    [Tip]                 CHAR (2)   NOT NULL,
    [Numar]               CHAR (8)   NOT NULL,
    [Data]                DATETIME   NOT NULL,
    [Gestiune]            CHAR (9)   NOT NULL,
    [Cod]                 CHAR (20)  NOT NULL,
    [Cod_intrare]         CHAR (13)  NOT NULL,
    [Serie]               CHAR (20)  NOT NULL,
    [Cantitate]           FLOAT (53) NOT NULL,
    [Tip_miscare]         CHAR (1)   NOT NULL,
    [Numar_pozitie]       INT        NOT NULL,
    [Gestiune_primitoare] CHAR (9)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KPDS]
    ON [dbo].[pdserii]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Numar_pozitie] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [Serie]
    ON [dbo].[pdserii]([Subunitate] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Serie] ASC);

