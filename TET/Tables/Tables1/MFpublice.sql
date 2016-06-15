CREATE TABLE [dbo].[MFpublice] (
    [Cod]      CHAR (20)      NOT NULL,
    [Denumire] VARCHAR (2000) NOT NULL,
    [detalii]  XML            NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MFpublice1]
    ON [dbo].[MFpublice]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [MFpublice2]
    ON [dbo].[MFpublice]([Denumire] ASC);

