CREATE TABLE [dbo].[CodImpExtras] (
    [Cod_operatie] CHAR (3)   NOT NULL,
    [Denumire]     CHAR (50)  NOT NULL,
    [Tip_pozplin]  CHAR (1)   NOT NULL,
    [Cont_coresp]  CHAR (13)  NOT NULL,
    [Explicatii]   CHAR (100) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[CodImpExtras]([Cod_operatie] ASC);

