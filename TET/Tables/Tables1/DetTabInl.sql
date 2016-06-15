CREATE TABLE [dbo].[DetTabInl] (
    [Tip]                   SMALLINT   NOT NULL,
    [Numar_tabela]          INT        NOT NULL,
    [Camp_Magic]            CHAR (30)  NOT NULL,
    [Camp_SQL]              CHAR (30)  NOT NULL,
    [Conditie_de_inlocuire] CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[DetTabInl]([Tip] ASC, [Numar_tabela] ASC, [Camp_SQL] ASC);

