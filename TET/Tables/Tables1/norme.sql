CREATE TABLE [dbo].[norme] (
    [Cod_norma]   CHAR (3)   NOT NULL,
    [Cod]         CHAR (20)  NOT NULL,
    [Ratie_vara]  FLOAT (53) NOT NULL,
    [Ratie_iarna] FLOAT (53) NOT NULL,
    [Calorii]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Norme1]
    ON [dbo].[norme]([Cod_norma] ASC, [Cod] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Norme2]
    ON [dbo].[norme]([Cod] ASC, [Cod_norma] ASC);

