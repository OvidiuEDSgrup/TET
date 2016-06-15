CREATE TABLE [dbo].[JurnalComenzi] (
    [idJurnal]   INT            IDENTITY (1, 1) NOT NULL,
    [idLansare]  INT            NULL,
    [data]       DATETIME       DEFAULT (getdate()) NULL,
    [stare]      VARCHAR (10)   NULL,
    [explicatii] VARCHAR (1000) NULL,
    [detalii]    XML            NULL,
    [utilizator] VARCHAR (100)  NULL
);


GO
CREATE NONCLUSTERED INDEX [idx_principal]
    ON [dbo].[JurnalComenzi]([idLansare] ASC);

