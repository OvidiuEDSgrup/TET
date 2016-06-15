CREATE TABLE [dbo].[Profesii] (
    [Profesie] CHAR (10) NOT NULL,
    [Denumire] CHAR (50) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Profesii]([Profesie] ASC);

