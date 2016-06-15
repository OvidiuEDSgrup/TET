CREATE TABLE [dbo].[penalizarifact] (
    [Tip]                   CHAR (2)     NOT NULL,
    [Tert]                  CHAR (13)    NOT NULL,
    [Factura]               CHAR (20)    NOT NULL,
    [Factura_penalizata]    CHAR (20)    NOT NULL,
    [Tip_doc_incasare]      CHAR (2)     NOT NULL,
    [Nr_doc_incasare]       CHAR (8)     NOT NULL,
    [Data_doc_incasare]     DATETIME     NOT NULL,
    [Sold_penalizare]       FLOAT (53)   NOT NULL,
    [Data_penalizare]       DATETIME     NOT NULL,
    [Zile_penalizare]       SMALLINT     NOT NULL,
    [Suma_penalizare]       FLOAT (53)   NOT NULL,
    [Valuta_penalizare]     CHAR (3)     NULL,
    [tip_penalizare]        CHAR (1)     NOT NULL,
    [Stare]                 VARCHAR (1)  NULL,
    [valid]                 INT          NULL,
    [contract_coresp]       VARCHAR (20) NULL,
    [procent_penalizare]    FLOAT (53)   NULL,
    [loc_de_munca]          VARCHAR (13) NULL,
    [factura_generata]      VARCHAR (20) NULL,
    [data_factura_generata] DATETIME     NULL,
    [punct_livrare]         VARCHAR (13) NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[penalizarifact]([Tip] ASC, [Tert] ASC, [Factura] ASC, [Factura_penalizata] ASC, [Tip_doc_incasare] ASC, [Nr_doc_incasare] ASC, [Data_doc_incasare] ASC, [Data_penalizare] ASC);


GO
CREATE NONCLUSTERED INDEX [Tert_factura]
    ON [dbo].[penalizarifact]([Tip] ASC, [Tert] ASC, [Factura] ASC, [Data_penalizare] ASC);

