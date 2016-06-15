CREATE TABLE [dbo].[surse] (
    [Cod]      CHAR (8)    NOT NULL,
    [Denumire] NCHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [pk_cod]
    ON [dbo].[surse]([Cod] ASC);

