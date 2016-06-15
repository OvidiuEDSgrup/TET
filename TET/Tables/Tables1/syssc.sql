CREATE TABLE [dbo].[syssc] (
    [Host_id]                    CHAR (10)    NOT NULL,
    [Host_name]                  CHAR (30)    NOT NULL,
    [Aplicatia]                  CHAR (30)    NOT NULL,
    [Data_stergerii]             DATETIME     NOT NULL,
    [Stergator]                  CHAR (10)    NOT NULL,
    [Subunitate]                 CHAR (9)     NOT NULL,
    [Cont]                       VARCHAR (20) NULL,
    [Denumire_cont]              CHAR (80)    NOT NULL,
    [Tip_cont]                   CHAR (1)     NOT NULL,
    [Cont_parinte]               VARCHAR (20) NULL,
    [Are_analitice]              BIT          NOT NULL,
    [Apare_in_balanta_sintetica] BIT          NOT NULL,
    [Sold_debit]                 FLOAT (53)   NOT NULL,
    [Sold_credit]                FLOAT (53)   NOT NULL,
    [Nivel]                      SMALLINT     NOT NULL,
    [Articol_de_calculatie]      CHAR (9)     NOT NULL,
    [Logic]                      BIT          NOT NULL
) ON [SYSS];

