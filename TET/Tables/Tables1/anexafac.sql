CREATE TABLE [dbo].[anexafac] (
    [Subunitate]          CHAR (9)   NOT NULL,
    [Numar_factura]       CHAR (20)  NOT NULL,
    [Numele_delegatului]  CHAR (30)  NOT NULL,
    [Seria_buletin]       CHAR (10)  NOT NULL,
    [Numar_buletin]       CHAR (10)  NOT NULL,
    [Eliberat]            CHAR (30)  NOT NULL,
    [Mijloc_de_transport] CHAR (30)  NOT NULL,
    [Numarul_mijlocului]  CHAR (13)  NOT NULL,
    [Data_expedierii]     DATETIME   NOT NULL,
    [Ora_expedierii]      CHAR (6)   NOT NULL,
    [Observatii]          CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sub_Factura]
    ON [dbo].[anexafac]([Subunitate] ASC, [Numar_factura] ASC);

