CREATE TABLE [dbo].[Strazi] (
    [Strada]          CHAR (8)  NOT NULL,
    [Denumire_Strada] CHAR (50) NOT NULL,
    [Cod_Localitate]  CHAR (8)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Strazi]([Strada] ASC);


GO
CREATE NONCLUSTERED INDEX [Alfabetic]
    ON [dbo].[Strazi]([Denumire_Strada] ASC);

