CREATE TABLE [dbo].[categs] (
    [Categoria_salarizare] CHAR (4)   NOT NULL,
    [Descriere]            CHAR (30)  NOT NULL,
    [Salar_orar]           FLOAT (53) NOT NULL,
    [Salar_lunar]          FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Categoria]
    ON [dbo].[categs]([Categoria_salarizare] ASC);

