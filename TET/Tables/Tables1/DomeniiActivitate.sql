CREATE TABLE [dbo].[DomeniiActivitate] (
    [idDomeniu] INT            IDENTITY (1, 1) NOT NULL,
    [descriere] VARCHAR (4000) NULL,
    [detalii]   XML            NULL,
    PRIMARY KEY CLUSTERED ([idDomeniu] ASC)
);

