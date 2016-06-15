CREATE TABLE [dbo].[rtva_tmp] (
    [codtert]        CHAR (13)    NULL,
    [codfisc]        CHAR (20)    NULL,
    [dentert]        CHAR (80)    NULL,
    [tipop]          CHAR (1)     NULL,
    [baza]           FLOAT (53)   NULL,
    [tva]            FLOAT (53)   NULL,
    [codNomenclator] VARCHAR (20) DEFAULT ('') NULL,
    [invers]         INT          DEFAULT ((0)) NULL
);

