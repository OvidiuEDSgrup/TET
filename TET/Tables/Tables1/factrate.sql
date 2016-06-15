CREATE TABLE [dbo].[factrate] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip_contract]   CHAR (2)   NOT NULL,
    [Data_contract]  DATETIME   NOT NULL,
    [Contract]       CHAR (20)  NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Numar_rata]     SMALLINT   NOT NULL,
    [Tip_plata]      CHAR (2)   NOT NULL,
    [Valoare]        FLOAT (53) NOT NULL,
    [Cota_TVA]       REAL       NOT NULL,
    [Suma_TVA]       FLOAT (53) NOT NULL,
    [Valuta]         CHAR (3)   NOT NULL,
    [Curs]           FLOAT (53) NOT NULL,
    [factura]        CHAR (20)  NOT NULL,
    [Data_facturii]  DATETIME   NOT NULL,
    [Numar_document] CHAR (8)   NOT NULL,
    [Cont_deb]       CHAR (13)  NOT NULL,
    [Cont_cred]      CHAR (13)  NOT NULL,
    [Explicatii]     CHAR (50)  NOT NULL,
    [Curs_calcul]    FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[factrate]([Subunitate] ASC, [Tip_contract] ASC, [Data_contract] ASC, [Contract] ASC, [Tert] ASC, [Numar_rata] ASC, [Tip_plata] DESC);


GO
CREATE NONCLUSTERED INDEX [Document]
    ON [dbo].[factrate]([Numar_document] ASC);


GO
CREATE NONCLUSTERED INDEX [Factura]
    ON [dbo].[factrate]([factura] ASC, [Data_facturii] ASC);

