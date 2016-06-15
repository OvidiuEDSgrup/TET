CREATE TABLE [dbo].[TipuriDocumente] (
    [idTip]    INT          IDENTITY (1, 1) NOT NULL,
    [tip]      VARCHAR (5)  NOT NULL,
    [denumire] VARCHAR (50) NULL,
    [detalii]  XML          NULL,
    PRIMARY KEY CLUSTERED ([tip] ASC)
);

