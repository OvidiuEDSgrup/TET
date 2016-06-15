CREATE TABLE [dbo].[logSincronizare] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [utilizator] VARCHAR (50) NULL,
    [data]       DATETIME     NULL,
    [date]       XML          NULL
);

