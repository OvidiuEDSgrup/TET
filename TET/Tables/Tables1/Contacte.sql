CREATE TABLE [dbo].[Contacte] (
    [idContact] INT           IDENTITY (1, 1) NOT NULL,
    [nume]      VARCHAR (300) NULL,
    [email]     VARCHAR (300) NULL,
    [telefon]   VARCHAR (300) NULL,
    [adresa]    VARCHAR (500) NULL,
    [profil]    VARCHAR (500) NULL,
    [note]      VARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([idContact] ASC)
);

