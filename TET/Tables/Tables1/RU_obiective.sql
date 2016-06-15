CREATE TABLE [dbo].[RU_obiective] (
    [ID_obiectiv]         INT           IDENTITY (1, 1) NOT NULL,
    [Denumire]            VARCHAR (MAX) NULL,
    [Categorie]           VARCHAR (1)   NULL,
    [Tip_obiectiv]        VARCHAR (1)   NULL,
    [ID_obiectiv_parinte] INT           NULL,
    [Loc_de_munca]        CHAR (9)      NULL,
    [Actiuni_realizare]   VARCHAR (MAX) NULL,
    [Actiuni_dezvoltare]  VARCHAR (MAX) NULL,
    [Rezultate]           VARCHAR (MAX) NULL,
    [Data_inceput]        DATETIME      NULL,
    [Data_sfarsit]        DATETIME      NULL,
    CONSTRAINT [PK_RU_obiective] PRIMARY KEY CLUSTERED ([ID_obiectiv] ASC)
);

