CREATE TABLE [dbo].[pcserii] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Comanda]    CHAR (13)  NOT NULL,
    [Cod]        CHAR (20)  NOT NULL,
    [Serie]      CHAR (20)  NOT NULL,
    [Cantitate]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KPCS]
    ON [dbo].[pcserii]([Subunitate] ASC, [Comanda] ASC, [Cod] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [Serie]
    ON [dbo].[pcserii]([Subunitate] ASC, [Serie] ASC);

