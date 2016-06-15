CREATE TABLE [dbo].[trasee] (
    [Cod]     CHAR (20) NOT NULL,
    [Plecare] CHAR (30) NOT NULL,
    [Sosire]  CHAR (30) NOT NULL,
    [Via]     CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[trasee]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Plecare]
    ON [dbo].[trasee]([Plecare] ASC);


GO
CREATE NONCLUSTERED INDEX [Sosire]
    ON [dbo].[trasee]([Sosire] ASC);


GO
CREATE NONCLUSTERED INDEX [Via]
    ON [dbo].[trasee]([Via] ASC);

