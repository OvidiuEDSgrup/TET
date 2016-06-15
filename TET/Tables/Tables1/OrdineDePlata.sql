CREATE TABLE [dbo].[OrdineDePlata] (
    [idOP]          INT            IDENTITY (1, 1) NOT NULL,
    [tip]           VARCHAR (20)   NULL,
    [cont_contabil] VARCHAR (20)   NULL,
    [data]          DATETIME       NULL,
    [Explicatii]    VARCHAR (2000) NULL,
    [detalii]       XML            NULL,
    PRIMARY KEY CLUSTERED ([idOP] ASC)
);

