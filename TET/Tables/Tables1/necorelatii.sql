CREATE TABLE [dbo].[necorelatii] (
    [tip_necorelatii] VARCHAR (2)   NULL,
    [tip_document]    VARCHAR (2)   NULL,
    [tip_alte]        VARCHAR (2)   NULL,
    [numar]           VARCHAR (20)  NULL,
    [data]            DATETIME      NULL,
    [cont]            VARCHAR (13)  NULL,
    [valoare_1]       FLOAT (53)    NULL,
    [valoare_2]       FLOAT (53)    NULL,
    [valoare_3]       FLOAT (53)    NULL,
    [valoare_4]       FLOAT (53)    NULL,
    [valuta]          VARCHAR (13)  NULL,
    [lm]              VARCHAR (13)  NULL,
    [msg_eroare]      VARCHAR (500) NULL,
    [utilizator]      VARCHAR (20)  NULL
);

