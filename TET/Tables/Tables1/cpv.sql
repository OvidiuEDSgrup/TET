CREATE TABLE [dbo].[cpv] (
    [id]        INT            IDENTITY (1, 1) NOT NULL,
    [idparinte] INT            NULL,
    [cod]       NVARCHAR (100) NULL,
    [denumire]  NVARCHAR (500) NULL,
    [detalii]   XML            DEFAULT (NULL) NULL
);


GO
CREATE CLUSTERED INDEX [indcod]
    ON [dbo].[cpv]([cod] ASC);


GO
CREATE NONCLUSTERED INDEX [indid]
    ON [dbo].[cpv]([id] ASC);

