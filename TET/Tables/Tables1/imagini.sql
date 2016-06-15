CREATE TABLE [dbo].[imagini] (
    [Tip]     CHAR (1)  NOT NULL,
    [Cod]     CHAR (20) NOT NULL,
    [Pozitie] INT       NOT NULL,
    [Obiect]  IMAGE     NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[imagini]([Tip] ASC, [Cod] ASC, [Pozitie] ASC);

