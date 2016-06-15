CREATE TABLE [dbo].[corespondente] (
    [Tip]              CHAR (20) NOT NULL,
    [cod]              CHAR (20) NOT NULL,
    [Cod_corespondent] CHAR (20) NOT NULL,
    [detalii]          XML       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Coresp1]
    ON [dbo].[corespondente]([Tip] ASC, [cod] ASC, [Cod_corespondent] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Coresp2]
    ON [dbo].[corespondente]([Tip] ASC, [Cod_corespondent] ASC, [cod] ASC);

