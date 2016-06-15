CREATE TABLE [dbo].[tmpSelectie] (
    [Terminal] CHAR (8)   NOT NULL,
    [Cod]      CHAR (100) NOT NULL,
    [Selectie] BIT        NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[tmpSelectie]([Terminal] ASC, [Cod] ASC);

