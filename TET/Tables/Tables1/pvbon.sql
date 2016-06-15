CREATE TABLE [dbo].[pvbon] (
    [Casa_de_marcat]    SMALLINT   NOT NULL,
    [Chitanta]          BIT        NOT NULL,
    [Numar_bon]         INT        NOT NULL,
    [Data_scadentei]    DATETIME   NOT NULL,
    [Loc_de_munca]      CHAR (9)   NOT NULL,
    [Agent]             CHAR (9)   NOT NULL,
    [Punct_de_livrare]  CHAR (5)   NOT NULL,
    [Categorie_de_pret] SMALLINT   NOT NULL,
    [Factura]           CHAR (20)  NOT NULL,
    [Contract]          CHAR (8)   NOT NULL,
    [Explicatii]        CHAR (30)  NOT NULL,
    [Valoare]           FLOAT (53) NOT NULL,
    [Comanda]           CHAR (13)  NOT NULL
);

