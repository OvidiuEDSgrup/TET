CREATE TABLE [dbo].[FURNIZORI_SOLD_FACTIMPL] (
    [Subunitate]            CHAR (9)   NOT NULL,
    [Loc_de_munca]          CHAR (9)   NOT NULL,
    [Tip]                   BINARY (1) NOT NULL,
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

