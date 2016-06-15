CREATE TABLE [dbo].[RU_nivele_organigrama] (
    [ID_nivel]          INT           IDENTITY (1, 1) NOT NULL,
    [Nivel_organigrama] INT           NULL,
    [Descriere]         VARCHAR (100) NULL,
    CONSTRAINT [PK_RU_nivele] PRIMARY KEY CLUSTERED ([ID_nivel] ASC)
);

