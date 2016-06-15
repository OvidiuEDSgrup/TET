CREATE TABLE [dbo].[fisa_lans] (
    [Hostid]           CHAR (20)  NOT NULL,
    [Comanda]          CHAR (13)  NOT NULL,
    [Cod_material]     CHAR (20)  NOT NULL,
    [Loc_de_munca]     CHAR (9)   NOT NULL,
    [Culoare_produs]   CHAR (20)  NOT NULL,
    [Culoare_material] CHAR (20)  NOT NULL,
    [Necesar]          FLOAT (53) NOT NULL,
    [Numar_material]   SMALLINT   NOT NULL,
    [Cod_produs]       CHAR (20)  NOT NULL,
    [Cod_parinte]      CHAR (20)  NOT NULL,
    [Cod_inlocuit]     CHAR (20)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[fisa_lans]([Hostid] ASC, [Comanda] ASC, [Cod_produs] ASC, [Cod_parinte] ASC, [Numar_material] ASC, [Cod_material] ASC, [Loc_de_munca] ASC, [Culoare_produs] ASC, [Culoare_material] ASC);


GO
CREATE NONCLUSTERED INDEX [Culoare_material]
    ON [dbo].[fisa_lans]([Hostid] ASC, [Comanda] ASC, [Cod_material] ASC, [Culoare_material] ASC, [Loc_de_munca] ASC);

