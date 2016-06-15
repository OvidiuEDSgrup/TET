CREATE TABLE [dbo].[deconttva] (
    [Data]               DATETIME   NOT NULL,
    [Capitol]            CHAR (2)   NOT NULL,
    [Rand_decont]        CHAR (10)  NOT NULL,
    [Denumire_indicator] CHAR (500) NOT NULL,
    [Valoare]            FLOAT (53) NOT NULL,
    [TVA]                FLOAT (53) NOT NULL,
    [Modif_valoare]      SMALLINT   NOT NULL,
    [Modif_tva]          SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[deconttva]([Data] ASC, [Capitol] ASC, [Rand_decont] ASC);

