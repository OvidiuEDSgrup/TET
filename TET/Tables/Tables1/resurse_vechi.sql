CREATE TABLE [dbo].[resurse_vechi] (
    [id]        INT          IDENTITY (1, 1) NOT NULL,
    [descriere] VARCHAR (80) NULL,
    [tip]       VARCHAR (16) NULL,
    [cod]       VARCHAR (20) NULL,
    [detalii]   XML          NULL
);

