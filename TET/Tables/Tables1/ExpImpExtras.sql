CREATE TABLE [dbo].[ExpImpExtras] (
    [Data_import]       DATETIME   NOT NULL,
    [Pozitie_import]    INT        NOT NULL,
    [Tert_import]       CHAR (13)  NOT NULL,
    [Factura]           CHAR (20)  NOT NULL,
    [Cont_factura]      CHAR (13)  NOT NULL,
    [Loc_de_munca]      CHAR (9)   NOT NULL,
    [Suma]              FLOAT (53) NOT NULL,
    [Pozitie_expandare] INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[ExpImpExtras]([Data_import] ASC, [Pozitie_import] ASC, [Factura] ASC);

