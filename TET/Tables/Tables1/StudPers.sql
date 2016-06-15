CREATE TABLE [dbo].[StudPers] (
    [Marca]           CHAR (6)  NOT NULL,
    [Numar_curs]      SMALLINT  NOT NULL,
    [Tip_curs]        CHAR (10) NOT NULL,
    [Denumire_curs]   CHAR (50) NOT NULL,
    [Localitate]      CHAR (15) NOT NULL,
    [Data_absolvirii] DATETIME  NOT NULL,
    [Durata]          CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[StudPers]([Marca] ASC, [Numar_curs] ASC);


GO
CREATE NONCLUSTERED INDEX [Detaliere]
    ON [dbo].[StudPers]([Marca] ASC, [Data_absolvirii] ASC, [Tip_curs] ASC);

