CREATE TABLE [dbo].[istoricserii] (
    [Subunitate]   CHAR (9)   NOT NULL,
    [Data_lunii]   DATETIME   NOT NULL,
    [Tip_gestiune] CHAR (1)   NOT NULL,
    [Gestiune]     CHAR (9)   NOT NULL,
    [Cod]          CHAR (20)  NOT NULL,
    [Cod_intrare]  CHAR (13)  NOT NULL,
    [Serie]        CHAR (20)  NOT NULL,
    [Stoc]         FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KIstserii]
    ON [dbo].[istoricserii]([Subunitate] ASC, [Data_lunii] ASC, [Tip_gestiune] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_Serie]
    ON [dbo].[istoricserii]([Subunitate] ASC, [Cod] ASC, [Serie] ASC);

