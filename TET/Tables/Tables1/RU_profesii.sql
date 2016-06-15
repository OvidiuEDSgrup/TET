CREATE TABLE [dbo].[RU_profesii] (
    [ID_profesie] INT           IDENTITY (1, 1) NOT NULL,
    [Denumire]    VARCHAR (30)  NULL,
    [Descriere]   VARCHAR (MAX) NULL,
    [Studii]      VARCHAR (MAX) NULL,
    CONSTRAINT [PK_RU_profesii] PRIMARY KEY CLUSTERED ([ID_profesie] ASC)
);

