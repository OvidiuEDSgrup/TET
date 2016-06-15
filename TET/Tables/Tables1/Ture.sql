CREATE TABLE [dbo].[Ture] (
    [Tura]        CHAR (1)  NOT NULL,
    [Denumire]    CHAR (30) NOT NULL,
    [Ora_inceput] CHAR (6)  NOT NULL,
    [Ora_sfarsit] CHAR (6)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Ture]([Tura] ASC, [Ora_inceput] ASC);

