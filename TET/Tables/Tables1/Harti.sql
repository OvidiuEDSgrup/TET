CREATE TABLE [dbo].[Harti] (
    [tip]        VARCHAR (2)       NOT NULL,
    [Cod]        VARCHAR (20)      NOT NULL,
    [Subcod]     VARCHAR (20)      NULL,
    [cx]         VARCHAR (10)      NULL,
    [cy]         VARCHAR (10)      NULL,
    [coordonate] [sys].[geography] NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PHarti]
    ON [dbo].[Harti]([tip] ASC, [Cod] ASC, [Subcod] ASC);

