CREATE TABLE [dbo].[Jurnale] (
    [Jurnal]     VARCHAR (20) NULL,
    [Descriere]  CHAR (75)    NOT NULL,
    [Utilizator] CHAR (10)    NOT NULL,
    [detalii]    XML          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[Jurnale]([Jurnal] ASC, [Utilizator] ASC);


GO
CREATE NONCLUSTERED INDEX [Utilizator]
    ON [dbo].[Jurnale]([Utilizator] ASC);

