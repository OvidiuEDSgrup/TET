CREATE TABLE [dbo].[PozOrdineDePlata] (
    [idPozOP]    INT            IDENTITY (1, 1) NOT NULL,
    [idOP]       INT            NULL,
    [banca_tert] VARCHAR (20)   NULL,
    [IBAN_tert]  VARCHAR (35)   NULL,
    [tip]        VARCHAR (20)   NULL,
    [explicatii] VARCHAR (2000) NULL,
    [suma]       FLOAT (53)     NULL,
    [stare]      VARCHAR (20)   NULL,
    [detalii]    XML            NULL,
    [documente]  XML            NULL,
    [tert]       VARCHAR (20)   NULL,
    [marca]      VARCHAR (20)   NULL,
    PRIMARY KEY CLUSTERED ([idPozOP] ASC),
    FOREIGN KEY ([idOP]) REFERENCES [dbo].[OrdineDePlata] ([idOP])
);

