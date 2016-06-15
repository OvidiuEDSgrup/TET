CREATE TABLE [dbo].[Catinfop] (
    [Cod]      CHAR (13) NOT NULL,
    [Denumire] CHAR (30) NOT NULL,
    [Tip]      CHAR (1)  NOT NULL,
    [pondere]  REAL      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[Catinfop]([Cod] ASC);

