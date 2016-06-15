CREATE TABLE [dbo].[realizari_vechi] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [codResursa] VARCHAR (20) NULL,
    [data]       DATETIME     NULL,
    [nrDoc]      VARCHAR (20) NULL,
    [detalii]    XML          NULL
);

