CREATE TABLE [dbo].[aplicatii] (
    [Nume]          CHAR (200) NOT NULL,
    [Cod_aplicatie] CHAR (2)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_aplic]
    ON [dbo].[aplicatii]([Cod_aplicatie] ASC);

