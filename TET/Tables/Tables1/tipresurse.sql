CREATE TABLE [dbo].[tipresurse] (
    [Cod]      CHAR (20) NOT NULL,
    [Denumire] CHAR (60) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[tipresurse]([Cod] ASC);

