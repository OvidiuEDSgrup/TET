CREATE TABLE [dbo].[schprod] (
    [Numar_curent] INT       NOT NULL,
    [Cod_nivel_1]  CHAR (20) NOT NULL,
    [Cod_nivel_2]  CHAR (20) NOT NULL,
    [Cod_nivel_3]  CHAR (20) NOT NULL,
    [Cod_nivel_4]  CHAR (20) NOT NULL,
    [Cod_nivel_5]  CHAR (20) NOT NULL,
    [Cod_nivel_6]  CHAR (20) NOT NULL,
    [Cod_nivel_7]  CHAR (20) NOT NULL,
    [Cod_nivel_8]  CHAR (20) NOT NULL,
    [Cod_nivel_9]  CHAR (20) NOT NULL,
    [Cod_nivel_10] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[schprod]([Numar_curent] ASC);

