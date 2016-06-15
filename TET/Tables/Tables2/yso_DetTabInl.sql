CREATE TABLE [dbo].[yso_DetTabInl] (
    [Tip]                   SMALLINT   NOT NULL,
    [Numar_tabela]          INT        NOT NULL,
    [Camp_Magic]            CHAR (30)  NOT NULL,
    [Camp_SQL]              CHAR (30)  NOT NULL,
    [Conditie_de_inlocuire] CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[yso_DetTabInl]([Tip] ASC, [Numar_tabela] ASC, [Camp_SQL] ASC);


GO
CREATE NONCLUSTERED INDEX [TblCol]
    ON [dbo].[yso_DetTabInl]([Tip] ASC, [Camp_Magic] ASC, [Camp_SQL] ASC) WITH (FILLFACTOR = 80);

