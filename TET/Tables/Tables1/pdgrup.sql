CREATE TABLE [dbo].[pdgrup] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Tip]           CHAR (2)   NOT NULL,
    [Numar]         CHAR (8)   NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Gestiune]      CHAR (9)   NOT NULL,
    [Cod]           CHAR (20)  NOT NULL,
    [Cod_intrare]   CHAR (13)  NOT NULL,
    [Cantitate]     FLOAT (53) NOT NULL,
    [Pret_de_stoc]  FLOAT (53) NOT NULL,
    [Pret_vanzare]  FLOAT (53) NOT NULL,
    [Tert]          CHAR (13)  NOT NULL,
    [Factura]       CHAR (20)  NOT NULL,
    [Numar_pozitie] INT        NOT NULL,
    [Grupa]         CHAR (13)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[pdgrup]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Factura]
    ON [dbo].[pdgrup]([Subunitate] ASC, [Tip] ASC, [Factura] ASC, [Tert] ASC);

