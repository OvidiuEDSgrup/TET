CREATE TABLE [dbo].[Module] (
    [Aplicatie] CHAR (2)   NOT NULL,
    [Cod]       SMALLINT   NOT NULL,
    [Descriere] CHAR (200) NOT NULL,
    [Bifat]     BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Module]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Aplicatie]
    ON [dbo].[Module]([Aplicatie] ASC);

