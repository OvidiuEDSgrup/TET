CREATE TABLE [dbo].[mot_service] (
    [Cod]       VARCHAR (5)  NOT NULL,
    [Descriere] VARCHAR (50) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[mot_service]([Cod] ASC);

