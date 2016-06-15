CREATE TABLE [dbo].[pozcontr] (
    [Subunitate]           CHAR (9)   NOT NULL,
    [Tip]                  CHAR (2)   NOT NULL,
    [Contract]             CHAR (20)  NOT NULL,
    [Tert]                 CHAR (13)  NOT NULL,
    [Cod]                  CHAR (20)  NOT NULL,
    [Cantitate]            FLOAT (53) NOT NULL,
    [Pret]                 FLOAT (53) NOT NULL,
    [Termen]               DATETIME   NOT NULL,
    [Factura]              CHAR (20)  NOT NULL,
    [Cantitate_realizata]  FLOAT (53) NOT NULL,
    [Valuta]               CHAR (13)  NOT NULL,
    [Mod_de_plata]         CHAR (13)  NOT NULL,
    [Data_inceperii]       DATETIME   NOT NULL,
    [Zi_scadenta_din_luna] SMALLINT   NOT NULL,
    [Numar_pozitie]        INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozcontr]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Cod] ASC, [Data_inceperii] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[pozcontr]([Subunitate] ASC, [Tip] ASC, [Cod] ASC);

