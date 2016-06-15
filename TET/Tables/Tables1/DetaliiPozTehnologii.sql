CREATE TABLE [dbo].[DetaliiPozTehnologii] (
    [idDetaliu]       INT            IDENTITY (1, 1) NOT NULL,
    [idPozTehnologii] INT            NULL,
    [ordine]          INT            NULL,
    [descriere]       VARCHAR (2000) NULL,
    [cantitate]       FLOAT (53)     NULL,
    [cod]             VARCHAR (20)   NULL,
    [scule]           VARCHAR (500)  NULL,
    [dispozitive]     VARCHAR (500)  NULL,
    [verificatoare]   VARCHAR (500)  NULL,
    [detalii]         XML            NULL
);

