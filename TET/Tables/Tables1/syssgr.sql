CREATE TABLE [yso].[syssgr] (
    [Host_id]            CHAR (10)      NOT NULL,
    [Host_name]          NVARCHAR (128) NULL,
    [Aplicatia]          VARCHAR (30)   NULL,
    [Data_stergerii]     DATETIME       NOT NULL,
    [Stergator]          VARCHAR (10)   NULL,
    [Tip_de_nomenclator] CHAR (1)       NOT NULL,
    [Grupa]              CHAR (13)      NOT NULL,
    [Denumire]           CHAR (120)     NULL,
    [Proprietate_1]      BIT            NOT NULL,
    [Proprietate_2]      BIT            NOT NULL,
    [Proprietate_3]      BIT            NOT NULL,
    [Proprietate_4]      BIT            NOT NULL,
    [Proprietate_5]      BIT            NOT NULL,
    [Proprietate_6]      BIT            NOT NULL,
    [Proprietate_7]      BIT            NOT NULL,
    [Proprietate_8]      BIT            NOT NULL,
    [Proprietate_9]      BIT            NOT NULL,
    [Proprietate_10]     BIT            NOT NULL
);

