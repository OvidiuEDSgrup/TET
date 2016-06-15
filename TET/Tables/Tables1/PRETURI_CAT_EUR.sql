CREATE TABLE [dbo].[PRETURI_CAT_EUR] (
    [nrcrt]          BIGINT        NULL,
    [LISTA]          VARCHAR (19)  NULL,
    [LIST_HEADER_ID] BIGINT        NULL,
    [MONEDA]         VARCHAR (3)   NULL,
    [COD]            VARCHAR (11)  NULL,
    [DENUMIRE]       VARCHAR (100) NULL,
    [PRET]           FLOAT (53)    NULL,
    [DATA_START]     DATETIME      NULL,
    [DATA_END]       VARCHAR (MAX) NULL
);

