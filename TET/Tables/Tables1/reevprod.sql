CREATE TABLE [dbo].[reevprod] (
    [Data]       DATETIME   NOT NULL,
    [Cod_produs] CHAR (20)  NOT NULL,
    [Tip]        CHAR (1)   NOT NULL,
    [Cod]        CHAR (20)  NOT NULL,
    [Cantitate]  FLOAT (53) NOT NULL,
    [Pret]       FLOAT (53) NOT NULL,
    [Explicatii] CHAR (50)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[reevprod]([Cod_produs] ASC, [Data] ASC, [Tip] ASC, [Cod] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Data]
    ON [dbo].[reevprod]([Data] ASC, [Cod_produs] ASC, [Tip] ASC, [Cod] ASC);

