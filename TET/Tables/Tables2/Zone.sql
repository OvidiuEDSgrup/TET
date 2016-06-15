CREATE TABLE [dbo].[Zone] (
    [Zona]          CHAR (8)  NOT NULL,
    [Denumire_zona] CHAR (50) NOT NULL,
    [Localitate]    CHAR (8)  NOT NULL,
    [Centru]        CHAR (8)  NOT NULL,
    [Cod_casier]    CHAR (10) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Princiipal]
    ON [dbo].[Zone]([Zona] ASC);

