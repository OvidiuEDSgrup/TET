CREATE TABLE [dbo].[actplinpeid] (
    [Gazda] CHAR (8)  NOT NULL,
    [Cod]   CHAR (20) NOT NULL,
    [Bifat] BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[actplinpeid]([Gazda] ASC, [Cod] ASC);

