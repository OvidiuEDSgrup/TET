CREATE TABLE [dbo].[VariabileUS] (
    [IDSesiune] CHAR (20)  NOT NULL,
    [Variabila] CHAR (20)  NOT NULL,
    [Valoare]   CHAR (100) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[VariabileUS]([IDSesiune] ASC, [Variabila] ASC);

