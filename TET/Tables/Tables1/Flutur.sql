CREATE TABLE [dbo].[Flutur] (
    [Hostid]        CHAR (10)  NOT NULL,
    [Numar_pozitie] INT        NOT NULL,
    [Tip_form]      CHAR (1)   NOT NULL,
    [Marca_i]       CHAR (6)   NULL,
    [Text_i]        CHAR (50)  NOT NULL,
    [Ore_procent_i] CHAR (20)  NOT NULL,
    [Valoare_i]     FLOAT (53) NULL,
    [Marca_p]       CHAR (6)   NULL,
    [Text_p]        CHAR (50)  NULL,
    [Ore_procent_p] CHAR (20)  NOT NULL,
    [Valoare_p]     FLOAT (53) NULL,
    [Marca]         CHAR (6)   NULL,
    [Text]          CHAR (50)  NULL,
    [Ore_procent]   CHAR (20)  NOT NULL,
    [Valoare]       FLOAT (53) NULL,
    [Nr_linie]      SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Tip_numar]
    ON [dbo].[Flutur]([Hostid] ASC, [Tip_form] ASC, [Numar_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Numar]
    ON [dbo].[Flutur]([Hostid] ASC, [Numar_pozitie] ASC, [Tip_form] ASC, [Marca_i] ASC, [Text_i] ASC, [Ore_procent_i] ASC, [Valoare_i] ASC);

