CREATE TABLE [dbo].[fisacmdtmp] (
    [Numar_de_ordine] INT        NOT NULL,
    [Nivel]           SMALLINT   NOT NULL,
    [Descriere]       CHAR (100) NOT NULL,
    [Cantitate]       FLOAT (53) NOT NULL,
    [Pret]            FLOAT (53) NOT NULL,
    [Valoare]         FLOAT (53) NOT NULL,
    [Tip]             CHAR (1)   NOT NULL,
    [Cod]             CHAR (20)  NOT NULL,
    [Locm]            CHAR (9)   NOT NULL,
    [Comanda_sup]     CHAR (13)  NOT NULL,
    [Art_sup]         CHAR (9)   NOT NULL,
    [NrOrdP]          INT        NOT NULL,
    [Unic]            INT        IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic_nr_ord]
    ON [dbo].[fisacmdtmp]([Numar_de_ordine] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic_identitate]
    ON [dbo].[fisacmdtmp]([Unic] ASC);

