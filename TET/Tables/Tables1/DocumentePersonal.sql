CREATE TABLE [dbo].[DocumentePersonal] (
    [idDocument]    INT           IDENTITY (1, 1) NOT NULL,
    [idTipDocument] INT           NULL,
    [marca]         VARCHAR (20)  NULL,
    [numar]         VARCHAR (20)  NULL,
    [serie]         VARCHAR (20)  NULL,
    [data_emiterii] DATETIME      NULL,
    [valabilitate]  DATETIME      NULL,
    [observatii]    VARCHAR (500) NULL,
    [fisier]        VARCHAR (500) NULL,
    [detalii]       XML           NULL
);

