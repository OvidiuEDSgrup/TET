CREATE TABLE [dbo].[RU_poz_instruiri] (
    [ID_poz_instruire] INT           IDENTITY (1, 1) NOT NULL,
    [ID_instruire]     INT           NULL,
    [ID_pers]          INT           NULL,
    [Marca]            CHAR (6)      NULL,
    [Durata]           INT           NULL,
    [Data_absolvirii]  DATETIME      NULL,
    [Nota]             FLOAT (53)    NULL,
    [Stare_pozitie]    CHAR (1)      NULL,
    [Explicatii]       CHAR (500)    NULL,
    [Data_operarii]    DATETIME      NULL,
    [Ora_operarii]     CHAR (6)      NULL,
    [Utilizator]       CHAR (10)     NULL,
    [Serie_diploma]    VARCHAR (10)  NULL,
    [Numar_diploma]    VARCHAR (20)  NULL,
    [Eliberat_diploma] VARCHAR (100) NULL,
    CONSTRAINT [PK_RU_poz_instruiri] PRIMARY KEY CLUSTERED ([ID_poz_instruire] ASC),
    CONSTRAINT [FK_RU_instruiri] FOREIGN KEY ([ID_instruire]) REFERENCES [dbo].[RU_instruiri] ([ID_instruire]) ON UPDATE CASCADE
);

