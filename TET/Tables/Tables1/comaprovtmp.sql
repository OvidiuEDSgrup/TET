CREATE TABLE [dbo].[comaprovtmp] (
    [Cod]             CHAR (30)  NOT NULL,
    [Furnizor]        CHAR (13)  NOT NULL,
    [Den_furnizor]    CHAR (80)  NOT NULL,
    [Total]           FLOAT (53) NOT NULL,
    [Media]           FLOAT (53) NOT NULL,
    [Com_clienti]     FLOAT (53) NOT NULL,
    [Stoc]            FLOAT (53) NOT NULL,
    [Stoc_limita]     FLOAT (53) NOT NULL,
    [Comandate]       FLOAT (53) NOT NULL,
    [De_aprovizionat] FLOAT (53) NOT NULL,
    [Pret]            FLOAT (53) NOT NULL,
    [Termen]          DATETIME   NOT NULL,
    [Utilizator]      CHAR (10)  NOT NULL,
    [Com_interne]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_nomencl]
    ON [dbo].[comaprovtmp]([Utilizator] ASC, [Cod] ASC);

