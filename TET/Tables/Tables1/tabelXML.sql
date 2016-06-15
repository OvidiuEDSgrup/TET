CREATE TABLE [dbo].[tabelXML] (
    [sesiune]         VARCHAR (50) DEFAULT (NULL) NOT NULL,
    [date]            XML          NULL,
    [data_modificare] DATETIME     DEFAULT (getdate()) NULL,
    CONSTRAINT [PrincimportXML] PRIMARY KEY CLUSTERED ([sesiune] ASC)
);

