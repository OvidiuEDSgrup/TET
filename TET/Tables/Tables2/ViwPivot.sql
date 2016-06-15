CREATE TABLE [dbo].[ViwPivot] (
    [Denumire]   CHAR (20)   NOT NULL,
    [Cale]       CHAR (200)  NOT NULL,
    [numeview]   CHAR (50)   NOT NULL,
    [Descriere]  CHAR (2000) NOT NULL,
    [Utilizator] CHAR (10)   NOT NULL,
    [Aplicatie]  CHAR (20)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[ViwPivot]([Utilizator] ASC, [Aplicatie] ASC, [Denumire] ASC);

