CREATE TABLE [dbo].[desenrep] (
    [Cod_reper] CHAR (20) NOT NULL,
    [Desen]     IMAGE     NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_reper]
    ON [dbo].[desenrep]([Cod_reper] ASC);

