CREATE TABLE [dbo].[istfact] (
    [Data_an]               DATETIME   NOT NULL,
    [Subunitate]            CHAR (9)   NOT NULL,
    [Loc_de_munca]          CHAR (9)   NOT NULL,
    [Tip]                   CHAR (1)   NOT NULL,
    [Factura]               CHAR (20)  NOT NULL,
    [Tert]                  CHAR (13)  NOT NULL,
    [Data]                  DATETIME   NOT NULL,
    [Data_scadentei]        DATETIME   NOT NULL,
    [Valoare]               FLOAT (53) NOT NULL,
    [TVA_11]                FLOAT (53) NOT NULL,
    [TVA_22]                FLOAT (53) NOT NULL,
    [Valuta]                CHAR (3)   NOT NULL,
    [Curs]                  FLOAT (53) NOT NULL,
    [Valoare_valuta]        FLOAT (53) NOT NULL,
    [Achitat]               FLOAT (53) NOT NULL,
    [Sold]                  FLOAT (53) NOT NULL,
    [Cont_de_tert]          CHAR (13)  NOT NULL,
    [Achitat_valuta]        FLOAT (53) NOT NULL,
    [Sold_valuta]           FLOAT (53) NOT NULL,
    [Comanda]               CHAR (40)  NOT NULL,
    [Data_ultimei_achitari] DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Ist_fact]
    ON [dbo].[istfact]([Data_an] ASC, [Subunitate] ASC, [Tip] ASC, [Factura] ASC, [Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [Factura]
    ON [dbo].[istfact]([Subunitate] ASC, [Tip] ASC, [Factura] ASC);


GO
CREATE NONCLUSTERED INDEX [Jurnale_TVA]
    ON [dbo].[istfact]([Data_an] ASC, [Subunitate] ASC, [Tip] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Tip_Tert]
    ON [dbo].[istfact]([Data_an] ASC, [Subunitate] ASC, [Tert] ASC, [Tip] ASC);

