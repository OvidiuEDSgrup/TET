CREATE TABLE [dbo].[ValidCat] (
    [Tip]        CHAR (5)  NOT NULL,
    [Cod]        CHAR (20) NOT NULL,
    [Data_jos]   DATETIME  NOT NULL,
    [Data_sus]   DATETIME  NOT NULL,
    [Explicatii] CHAR (50) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[ValidCat]([Tip] ASC, [Cod] ASC);

