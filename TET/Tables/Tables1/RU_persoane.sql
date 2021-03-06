﻿CREATE TABLE [dbo].[RU_persoane] (
    [ID_pers]       INT           IDENTITY (1, 1) NOT NULL,
    [Tip]           VARCHAR (1)   NULL,
    [Marca]         VARCHAR (6)   NULL,
    [Email]         VARCHAR (200) NULL,
    [Telefon_fix]   VARCHAR (30)  NULL,
    [Telefon_mobil] VARCHAR (30)  NULL,
    [OpenID]        VARCHAR (100) NULL,
    [Idmessenger]   VARCHAR (50)  NULL,
    [Idfacebook]    VARCHAR (50)  NULL,
    [ID_profesie]   INT           NULL,
    [Diploma]       VARCHAR (100) NULL,
    [CNP]           VARCHAR (13)  NULL,
    [Serie_BI]      VARCHAR (2)   NULL,
    [Numar_BI]      VARCHAR (10)  NULL,
    [Nume]          VARCHAR (100) NULL,
    [Cod_functie]   VARCHAR (6)   NULL,
    [Loc_de_munca]  VARCHAR (9)   NULL,
    [Judet]         VARCHAR (15)  NULL,
    [Localitate]    VARCHAR (30)  NULL,
    [Strada]        VARCHAR (50)  NULL,
    [Numar]         VARCHAR (5)   NULL,
    [Cod_postal]    INT           NULL,
    [Bloc]          VARCHAR (10)  NULL,
    [Scara]         VARCHAR (2)   NULL,
    [Etaj]          VARCHAR (2)   NULL,
    [Apartament]    VARCHAR (5)   NULL,
    [Sector]        INT           NULL,
    [Data_inreg]    DATETIME      NULL,
    [Detalii]       XML           NULL,
    CONSTRAINT [PK_RU_Persoane] PRIMARY KEY CLUSTERED ([ID_pers] ASC),
    CONSTRAINT [FK_RU_profesii] FOREIGN KEY ([ID_profesie]) REFERENCES [dbo].[RU_profesii] ([ID_profesie]) ON UPDATE CASCADE
);

