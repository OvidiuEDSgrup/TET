CREATE TABLE [dbo].[bancibnr] (
    [Cod]      CHAR (20) NOT NULL,
    [Denumire] CHAR (50) NOT NULL,
    [Filiala]  CHAR (50) NOT NULL,
    [Judet]    CHAR (20) NOT NULL,
    [Tip]      CHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[bancibnr]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Judet]
    ON [dbo].[bancibnr]([Judet] ASC);

