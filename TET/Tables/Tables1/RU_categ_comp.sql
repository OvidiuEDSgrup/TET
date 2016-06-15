CREATE TABLE [dbo].[RU_categ_comp] (
    [ID_categ_comp] INT           IDENTITY (1, 1) NOT NULL,
    [Denumire]      VARCHAR (30)  NULL,
    [Descriere]     VARCHAR (MAX) NULL,
    CONSTRAINT [PK_RU_categ_comp] PRIMARY KEY CLUSTERED ([ID_categ_comp] ASC)
);

