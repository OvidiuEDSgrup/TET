CREATE TABLE [dbo].[descp] (
    [Cod_proprietate] CHAR (20) NOT NULL,
    [Cod_valid]       CHAR (20) NOT NULL,
    [Descriere]       CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cheie_unica]
    ON [dbo].[descp]([Cod_proprietate] ASC, [Cod_valid] ASC);

