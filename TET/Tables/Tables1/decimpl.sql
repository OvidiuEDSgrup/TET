CREATE TABLE [dbo].[decimpl] (
    [Subunitate]             CHAR (9)     NOT NULL,
    [Tip]                    CHAR (1)     NOT NULL,
    [Marca]                  CHAR (6)     NOT NULL,
    [Decont]                 CHAR (13)    NOT NULL,
    [Cont]                   VARCHAR (20) NULL,
    [Data]                   DATETIME     NOT NULL,
    [Data_scadentei]         DATETIME     NOT NULL,
    [Valoare]                FLOAT (53)   NOT NULL,
    [Valuta]                 CHAR (3)     NOT NULL,
    [Curs]                   FLOAT (53)   NOT NULL,
    [Valoare_valuta]         FLOAT (53)   NOT NULL,
    [Decontat]               FLOAT (53)   NOT NULL,
    [Sold]                   FLOAT (53)   NOT NULL,
    [Decontat_valuta]        FLOAT (53)   NOT NULL,
    [Sold_valuta]            FLOAT (53)   NOT NULL,
    [Loc_de_munca]           CHAR (9)     NOT NULL,
    [Comanda]                CHAR (40)    NOT NULL,
    [Data_ultimei_decontari] DATETIME     NOT NULL,
    [Explicatii]             CHAR (30)    NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Declaimpl]
    ON [dbo].[decimpl]([Subunitate] ASC, [Tip] ASC, [Marca] ASC, [Decont] ASC);


GO
CREATE NONCLUSTERED INDEX [DeciMarca]
    ON [dbo].[decimpl]([Subunitate] ASC, [Marca] ASC, [Tip] ASC);

