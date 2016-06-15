CREATE TABLE [dbo].[grspor] (
    [Cod]     CHAR (2) NOT NULL,
    [NrCrt]   SMALLINT NOT NULL,
    [Limita]  REAL     NOT NULL,
    [Procent] REAL     NOT NULL,
    [Suma]    SMALLINT NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_Numar]
    ON [dbo].[grspor]([Cod] ASC, [NrCrt] ASC);

