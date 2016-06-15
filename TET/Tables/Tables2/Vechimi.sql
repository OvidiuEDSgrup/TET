CREATE TABLE [dbo].[Vechimi] (
    [Marca]         CHAR (6)  NOT NULL,
    [Tip]           CHAR (1)  NOT NULL,
    [Numar_pozitie] SMALLINT  NOT NULL,
    [Data_inceput]  DATETIME  NOT NULL,
    [Data_sfarsit]  DATETIME  NOT NULL,
    [Unitate]       CHAR (30) NOT NULL,
    [Loc_de_munca]  CHAR (30) NOT NULL,
    [Functie]       CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Vechimi]
    ON [dbo].[Vechimi]([Marca] ASC, [Tip] ASC, [Numar_pozitie] ASC);

