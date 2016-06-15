CREATE TABLE [dbo].[actfactpeid] (
    [Gazda] CHAR (8)  NOT NULL,
    [Cod]   CHAR (20) NOT NULL,
    [Bifat] BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Prin]
    ON [dbo].[actfactpeid]([Gazda] ASC, [Cod] ASC);

