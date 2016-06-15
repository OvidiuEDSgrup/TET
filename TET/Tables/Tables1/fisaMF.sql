CREATE TABLE [dbo].[fisaMF] (
    [Subunitate]                   CHAR (9)     NOT NULL,
    [Numar_de_inventar]            CHAR (13)    NOT NULL,
    [Categoria]                    SMALLINT     NOT NULL,
    [Data_lunii_operatiei]         DATETIME     NOT NULL,
    [Felul_operatiei]              CHAR (1)     NOT NULL,
    [Loc_de_munca]                 CHAR (9)     NOT NULL,
    [Gestiune]                     CHAR (9)     NOT NULL,
    [Comanda]                      CHAR (40)    NOT NULL,
    [Valoare_de_inventar]          FLOAT (53)   NOT NULL,
    [Valoare_amortizata]           FLOAT (53)   NOT NULL,
    [Valoare_amortizata_cont_8045] FLOAT (53)   NOT NULL,
    [Valoare_amortizata_cont_6871] FLOAT (53)   NOT NULL,
    [Amortizare_lunara]            FLOAT (53)   NOT NULL,
    [Amortizare_lunara_cont_8045]  FLOAT (53)   NOT NULL,
    [Amortizare_lunara_cont_6871]  FLOAT (53)   NOT NULL,
    [Durata]                       SMALLINT     NOT NULL,
    [Obiect_de_inventar]           BIT          NOT NULL,
    [Cont_mijloc_fix]              VARCHAR (20) NULL,
    [Numar_de_luni_pana_la_am_int] SMALLINT     NOT NULL,
    [Cantitate]                    FLOAT (53)   NOT NULL,
    [Cont_amortizare]              VARCHAR (40) NULL,
    [Cont_cheltuieli]              VARCHAR (40) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Subunitate_Nrinv_Perioada]
    ON [dbo].[fisaMF]([Subunitate] ASC, [Numar_de_inventar] ASC, [Data_lunii_operatiei] ASC, [Felul_operatiei] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_calcul]
    ON [dbo].[fisaMF]([Subunitate] ASC, [Data_lunii_operatiei] DESC, [Numar_de_inventar] ASC, [Felul_operatiei] DESC);


GO
CREATE NONCLUSTERED INDEX [Pentru_balanta]
    ON [dbo].[fisaMF]([Subunitate] ASC, [Data_lunii_operatiei] ASC, [Felul_operatiei] ASC, [Cont_mijloc_fix] ASC);

