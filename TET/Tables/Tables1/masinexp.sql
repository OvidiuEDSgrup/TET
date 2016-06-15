CREATE TABLE [dbo].[masinexp] (
    [Numarul_mijlocului] CHAR (10) NOT NULL,
    [Descriere]          CHAR (30) NOT NULL,
    [Furnizor]           CHAR (13) NOT NULL,
    [Delegat]            CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [idx_principal]
    ON [dbo].[masinexp]([Furnizor] ASC, [Numarul_mijlocului] ASC);

