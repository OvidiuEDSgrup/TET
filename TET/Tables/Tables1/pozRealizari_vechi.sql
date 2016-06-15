CREATE TABLE [dbo].[pozRealizari_vechi] (
    [id]            INT           IDENTITY (1, 1) NOT NULL,
    [idPlanificare] INT           NULL,
    [idRealizare]   INT           NULL,
    [cantitate]     FLOAT (53)    NULL,
    [observatii]    VARCHAR (400) NULL,
    [detalii]       XML           NULL,
    [idTehnologie]  INT           NULL,
    [CM]            VARCHAR (13)  NULL,
    [PP]            VARCHAR (13)  NULL
);

