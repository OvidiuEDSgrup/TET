CREATE TABLE [dbo].[tmpArticoleCentralizator] (
    [utilizator]         VARCHAR (100) NULL,
    [idTmp]              INT           IDENTITY (1, 1) NOT NULL,
    [cod]                VARCHAR (20)  NULL,
    [cod_specific]       VARCHAR (20)  NULL,
    [furnizor]           VARCHAR (20)  NULL,
    [cantitate]          FLOAT (53)    NULL,
    [cant_rezervata]     FLOAT (53)    NULL,
    [cant_aprovizionare] FLOAT (53)    NULL,
    [pret]               FLOAT (53)    NULL,
    [curs]               FLOAT (53)    NULL,
    [valuta]             VARCHAR (20)  NULL,
    [decomandat]         FLOAT (53)    NULL,
    [stoc]               FLOAT (53)    NULL,
    [tip]                VARCHAR (1)   NULL
);

