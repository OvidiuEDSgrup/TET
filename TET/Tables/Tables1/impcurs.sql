CREATE TABLE [dbo].[impcurs] (
    [Cod]              CHAR (20)  NOT NULL,
    [Cod_intrare]      CHAR (13)  NOT NULL,
    [Den_original]     CHAR (30)  NOT NULL,
    [Den_romana]       CHAR (30)  NOT NULL,
    [Cantitate]        FLOAT (53) NOT NULL,
    [Serie]            CHAR (9)   NOT NULL,
    [An_fabr]          SMALLINT   NOT NULL,
    [Valuta]           CHAR (3)   NOT NULL,
    [Pret]             FLOAT (53) NOT NULL,
    [Dobanda]          FLOAT (53) NOT NULL,
    [Nr_sumara]        CHAR (8)   NOT NULL,
    [Data_sumara]      DATETIME   NOT NULL,
    [Curs_sumara]      FLOAT (53) NOT NULL,
    [Furnizor]         CHAR (13)  NOT NULL,
    [Factura]          CHAR (20)  NOT NULL,
    [Data_fact]        DATETIME   NOT NULL,
    [DVI]              CHAR (8)   NOT NULL,
    [Data_DVI]         DATETIME   NOT NULL,
    [Curs_DVI]         FLOAT (53) NOT NULL,
    [Transportator]    CHAR (13)  NOT NULL,
    [Fact_transp]      CHAR (20)  NOT NULL,
    [Data_fact_transp] DATETIME   NOT NULL,
    [Val_transp]       FLOAT (53) NOT NULL,
    [Stare]            CHAR (1)   NOT NULL,
    [Tip_operatie]     CHAR (1)   NOT NULL,
    [Cont]             CHAR (13)  NOT NULL,
    [Valoare]          FLOAT (53) NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL,
    [Loc_de_munca]     CHAR (9)   NOT NULL,
    [Comanda]          CHAR (13)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Impcurs1]
    ON [dbo].[impcurs]([Cod_intrare] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Impcurs2]
    ON [dbo].[impcurs]([Cod] ASC, [Cod_intrare] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Impcurs3]
    ON [dbo].[impcurs]([Nr_sumara] ASC, [Data_sumara] ASC, [Cod_intrare] ASC);


GO
CREATE NONCLUSTERED INDEX [Impcurs4]
    ON [dbo].[impcurs]([DVI] ASC, [Data_DVI] ASC, [Stare] ASC);

