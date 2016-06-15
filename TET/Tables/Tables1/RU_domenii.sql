CREATE TABLE [dbo].[RU_domenii] (
    [ID_domeniu] INT           IDENTITY (1, 1) NOT NULL,
    [Denumire]   VARCHAR (50)  NULL,
    [Descriere]  VARCHAR (MAX) NULL,
    CONSTRAINT [PK_RU_domenii] PRIMARY KEY CLUSTERED ([ID_domeniu] ASC)
);

