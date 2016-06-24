CREATE TABLE [dbo].[pozFactBenefTmp] (
    [Terminal]        CHAR (10)  NOT NULL,
    [Subunitate]      CHAR (9)   NOT NULL,
    [Numar_document]  CHAR (8)   NOT NULL,
    [Data]            DATETIME   NOT NULL,
    [Tert]            CHAR (13)  NOT NULL,
    [Tip]             CHAR (2)   NOT NULL,
    [Factura_stinga]  CHAR (20)  NOT NULL,
    [Factura_dreapta] CHAR (20)  NOT NULL,
    [sumaFactSt]      FLOAT (53) NOT NULL,
    [tvaFactSt]       FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [unic]
    ON [dbo].[pozFactBenefTmp]([Terminal] ASC, [Subunitate] ASC, [Tip] ASC, [Numar_document] ASC, [Data] ASC, [Tert] ASC, [Factura_stinga] ASC, [Factura_dreapta] ASC);

