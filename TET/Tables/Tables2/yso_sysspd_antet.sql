CREATE TABLE [dbo].[yso_sysspd_antet] (
    [Host_id]        CHAR (10)       NOT NULL,
    [Host_name]      CHAR (30)       NOT NULL,
    [Aplicatia]      CHAR (30)       NOT NULL,
    [Data_operatiei] DATETIME        NOT NULL,
    [Operator]       CHAR (10)       NOT NULL,
    [eveniment]      NVARCHAR (100)  NULL,
    [parametri]      INT             NULL,
    [comanda]        NVARCHAR (4000) NULL
);

