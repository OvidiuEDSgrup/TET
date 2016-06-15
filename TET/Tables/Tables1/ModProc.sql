CREATE TABLE [dbo].[ModProc] (
    [Variabila] SMALLINT  NOT NULL,
    [Denumire]  CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[ModProc]([Variabila] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[ModProc]([Denumire] ASC);

