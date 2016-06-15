CREATE TABLE [dbo].[Tehncul] (
    [Cod_reper]    CHAR (20) NOT NULL,
    [Cod_material] CHAR (20) NOT NULL,
    [Culoare]      CHAR (20) NOT NULL,
    [Numar_fire]   SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Tehncul]([Cod_reper] ASC, [Cod_material] ASC, [Culoare] ASC);

