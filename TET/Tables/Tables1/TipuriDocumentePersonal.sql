CREATE TABLE [dbo].[TipuriDocumentePersonal] (
    [idTipDocument]         INT           IDENTITY (1, 1) NOT NULL,
    [tip]                   VARCHAR (100) NULL,
    [valabilitate_standard] INT           NULL,
    [descriere]             VARCHAR (300) NULL,
    [cod_functie]           VARCHAR (20)  NULL,
    [detalii]               XML           NULL
);

