CREATE TABLE [dbo].[pozLansari_vechi] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [tip]        VARCHAR (1)  NULL,
    [cod]        VARCHAR (20) NULL,
    [cantitate]  FLOAT (53)   NULL,
    [idp]        INT          NULL,
    [parinteTop] INT          NULL,
    [detalii]    XML          NULL
);

