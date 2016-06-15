CREATE TABLE [dbo].[Promotii] (
    [idPromotie]      INT           IDENTITY (1, 1) NOT NULL,
    [furnizor]        VARCHAR (20)  NULL,
    [dela]            DATETIME      NULL,
    [panala]          DATETIME      NULL,
    [denumire]        VARCHAR (500) NULL,
    [cod]             VARCHAR (20)  NULL,
    [cantitate]       FLOAT (53)    NULL,
    [cantitate_promo] FLOAT (53)    NULL,
    PRIMARY KEY CLUSTERED ([idPromotie] ASC)
);

