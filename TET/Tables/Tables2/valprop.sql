CREATE TABLE [dbo].[valprop] (
    [Cod]             CHAR (20) NOT NULL,
    [Cod_proprietate] CHAR (20) NOT NULL,
    [Valoare]         CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[valprop]([Cod] ASC, [Cod_proprietate] ASC, [Valoare] ASC);


GO
CREATE NONCLUSTERED INDEX [Valoare_proprietate]
    ON [dbo].[valprop]([Valoare] ASC);

