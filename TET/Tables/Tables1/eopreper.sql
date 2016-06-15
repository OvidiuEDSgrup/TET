CREATE TABLE [dbo].[eopreper] (
    [Cod_reper]      CHAR (20)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [Numar_operatie] SMALLINT   NOT NULL,
    [Numar_pozitie]  INT        NOT NULL,
    [Denumire]       CHAR (100) NOT NULL,
    [Cod_material]   CHAR (20)  NOT NULL,
    [Cantitate]      FLOAT (53) NOT NULL,
    [Procent]        REAL       NOT NULL,
    [Rezerva]        CHAR (20)  NOT NULL,
    [Valoare]        FLOAT (53) NOT NULL,
    [SDV1]           CHAR (30)  NOT NULL,
    [SDV2]           CHAR (30)  NOT NULL,
    [SDV3]           CHAR (30)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CodRep_NrOp]
    ON [dbo].[eopreper]([Cod_reper] ASC, [Numar_operatie] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [CodRep_CodOp]
    ON [dbo].[eopreper]([Cod_reper] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[eopreper]([Denumire] ASC);

