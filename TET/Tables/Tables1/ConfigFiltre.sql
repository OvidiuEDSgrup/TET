CREATE TABLE [dbo].[ConfigFiltre] (
    [Tip]        CHAR (1)   NOT NULL,
    [Utilizator] CHAR (10)  NOT NULL,
    [Cod_filtru] CHAR (20)  NOT NULL,
    [Valoare]    CHAR (100) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[ConfigFiltre]([Tip] ASC, [Utilizator] ASC, [Cod_filtru] ASC, [Valoare] ASC);

