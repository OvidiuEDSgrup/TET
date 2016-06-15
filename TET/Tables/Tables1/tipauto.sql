CREATE TABLE [dbo].[tipauto] (
    [Cod]        VARCHAR (10) NOT NULL,
    [Marca]      VARCHAR (30) NOT NULL,
    [Model]      VARCHAR (30) NOT NULL,
    [Versiune]   VARCHAR (30) NOT NULL,
    [Tip_motor]  VARCHAR (20) NOT NULL,
    [Capacitate] VARCHAR (10) NOT NULL,
    [Putere]     VARCHAR (10) NOT NULL,
    [Grupa]      VARCHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tipauto]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Grupa]
    ON [dbo].[tipauto]([Grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [Secundar]
    ON [dbo].[tipauto]([Marca] ASC);


GO
CREATE NONCLUSTERED INDEX [Tertiar]
    ON [dbo].[tipauto]([Model] ASC);

