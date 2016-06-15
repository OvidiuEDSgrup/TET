CREATE TABLE [dbo].[configmeniu] (
    [Tip]        CHAR (1)       NOT NULL,
    [Utilizator] CHAR (10)      NOT NULL,
    [Bara]       CHAR (50)      NOT NULL,
    [Numar]      DECIMAL (9, 4) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[configmeniu]([Tip] ASC, [Utilizator] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_bara]
    ON [dbo].[configmeniu]([Tip] ASC, [Utilizator] ASC, [Bara] ASC);

