CREATE TABLE [dbo].[AntetRectificariSalarii] (
    [idRectificare] INT           IDENTITY (1, 1) NOT NULL,
    [data]          DATETIME      NULL,
    [marca]         VARCHAR (6)   NULL,
    [explicatii]    VARCHAR (100) NULL,
    [detalii]       XML           NULL,
    PRIMARY KEY CLUSTERED ([idRectificare] ASC)
);

