CREATE TABLE [dbo].[asortari] (
    [Terminal]            CHAR (9)  NOT NULL,
    [Cod_produs]          CHAR (20) NOT NULL,
    [Cod_material]        CHAR (20) NOT NULL,
    [Loc_de_munca]        CHAR (9)  NOT NULL,
    [Culoare_produs]      CHAR (20) NOT NULL,
    [Culoare_material_10] CHAR (20) NOT NULL,
    [Numar_material]      SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[asortari]([Terminal] ASC, [Cod_produs] ASC, [Culoare_produs] ASC, [Numar_material] ASC);


GO
CREATE NONCLUSTERED INDEX [Asortari]
    ON [dbo].[asortari]([Terminal] ASC, [Cod_produs] ASC, [Cod_material] ASC, [Loc_de_munca] ASC, [Culoare_produs] ASC);

