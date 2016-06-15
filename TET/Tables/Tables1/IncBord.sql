CREATE TABLE [dbo].[IncBord] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Numar]          CHAR (8)   NOT NULL,
    [Data_incasare]  DATETIME   NOT NULL,
    [Factura]        CHAR (20)  NOT NULL,
    [Suma]           FLOAT (53) NOT NULL,
    [Explicatii]     CHAR (50)  NOT NULL,
    [Cont_doc]       CHAR (13)  NOT NULL,
    [Data_doc]       DATETIME   NOT NULL,
    [Pozitie_doc]    INT        NOT NULL,
    [Numar_doc]      CHAR (10)  NOT NULL,
    [Pozitie_storno] INT        NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[IncBord]([Subunitate] ASC, [Numar] ASC, [Factura] ASC);

