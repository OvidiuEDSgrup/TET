CREATE TABLE [dbo].[infonom] (
    [Cod]                  CHAR (20)  NOT NULL,
    [Finete]               CHAR (20)  NOT NULL,
    [Filamente]            REAL       NOT NULL,
    [Torsiune]             REAL       NOT NULL,
    [Numar_metric]         FLOAT (53) NOT NULL,
    [Densitate_de_lungime] CHAR (3)   NOT NULL,
    [Culoare]              CHAR (10)  NOT NULL,
    [Greutate_cauciuc]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[infonom]([Cod] ASC);

