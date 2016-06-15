CREATE TABLE [dbo].[syssm] (
    [Host_id]                   CHAR (10)    NOT NULL,
    [Host_name]                 CHAR (30)    NOT NULL,
    [Aplicatia]                 CHAR (30)    NOT NULL,
    [Data_stergerii]            DATETIME     NOT NULL,
    [Stergator]                 CHAR (10)    NOT NULL,
    [Subunitate]                CHAR (9)     NOT NULL,
    [Numar_de_inventar]         CHAR (13)    NOT NULL,
    [Denumire]                  CHAR (80)    NOT NULL,
    [Serie]                     CHAR (20)    NOT NULL,
    [Tip_amortizare]            CHAR (1)     NOT NULL,
    [Cod_de_clasificare]        VARCHAR (20) NULL,
    [Data_punerii_in_functiune] DATETIME     NOT NULL
) ON [SYSS];

