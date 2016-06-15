CREATE TABLE [dbo].[LMFiltrare] (
    [utilizator] VARCHAR (50) NULL,
    [cod]        VARCHAR (20) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Idx1]
    ON [dbo].[LMFiltrare]([utilizator] ASC, [cod] ASC);

