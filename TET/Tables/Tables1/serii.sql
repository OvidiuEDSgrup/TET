CREATE TABLE [dbo].[serii] (
    [Subunitate]   CHAR (9)   NOT NULL,
    [Tip_gestiune] CHAR (1)   NOT NULL,
    [Gestiune]     CHAR (9)   NOT NULL,
    [Cod]          CHAR (20)  NOT NULL,
    [Cod_intrare]  CHAR (13)  NOT NULL,
    [Serie]        CHAR (20)  NOT NULL,
    [Stoc_initial] FLOAT (53) NOT NULL,
    [Intrari]      FLOAT (53) NOT NULL,
    [Iesiri]       FLOAT (53) NOT NULL,
    [Stoc]         FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KSerii]
    ON [dbo].[serii]([Subunitate] ASC, [Tip_gestiune] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Cod_Serie]
    ON [dbo].[serii]([Subunitate] ASC, [Cod] ASC, [Serie] ASC);

