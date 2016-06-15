CREATE TABLE [dbo].[RU_organigrama] (
    [ID_organigrama]      INT      IDENTITY (1, 1) NOT NULL,
    [Cod_functie]         CHAR (6) NULL,
    [Cod_functie_parinte] CHAR (6) NULL,
    [Data_inceput]        DATETIME NULL,
    [Data_sfarsit]        DATETIME NULL,
    [ID_nivel]            INT      NULL,
    [Numar_posturi]       INT      NULL,
    [Ordine_stat]         INT      NULL,
    CONSTRAINT [PK_RU_organigrama] PRIMARY KEY CLUSTERED ([ID_organigrama] ASC),
    CONSTRAINT [FK_RU_niveleorg] FOREIGN KEY ([ID_nivel]) REFERENCES [dbo].[RU_nivele_organigrama] ([ID_nivel]) ON UPDATE CASCADE
);

