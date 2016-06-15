CREATE TABLE [dbo].[testamm] (
    [cod]             CHAR (30)   NOT NULL,
    [furnizor]        CHAR (13)   NOT NULL,
    [den_furn]        CHAR (80)   NOT NULL,
    [total]           FLOAT (53)  NOT NULL,
    [media]           FLOAT (53)  NULL,
    [com_clienti]     INT         NOT NULL,
    [stoc]            FLOAT (53)  NOT NULL,
    [stoc_limita]     FLOAT (53)  NULL,
    [comandate]       FLOAT (53)  NOT NULL,
    [de_aprovizionat] INT         NOT NULL,
    [pret]            FLOAT (53)  NULL,
    [ceva]            DATETIME    NULL,
    [utiliz]          VARCHAR (6) NOT NULL,
    [Com_interne]     INT         NOT NULL
);

