CREATE TABLE [dbo].[tmpPozArticoleCentralizator] (
    [utilizator]         VARCHAR (100) NULL,
    [cod]                VARCHAR (20)  NULL,
    [cantitate]          FLOAT (53)    NULL,
    [idPozContract]      INT           NULL,
    [idPozLansare]       INT           NULL,
    [cant_aprovizionare] FLOAT (53)    NULL,
    [idTmp]              INT           IDENTITY (1, 1) NOT NULL
);

