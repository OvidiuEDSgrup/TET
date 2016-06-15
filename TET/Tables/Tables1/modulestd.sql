CREATE TABLE [dbo].[modulestd] (
    [Aplicatie] CHAR (2)   NOT NULL,
    [Cod]       SMALLINT   NOT NULL,
    [Descriere] CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[modulestd]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Aplicatie]
    ON [dbo].[modulestd]([Aplicatie] ASC);

