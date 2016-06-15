CREATE TABLE [dbo].[meniuri] (
    [Bara]      CHAR (50)      NOT NULL,
    [Descriere] CHAR (150)     NOT NULL,
    [Numar]     DECIMAL (9, 4) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[meniuri]([Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_bara]
    ON [dbo].[meniuri]([Bara] ASC);

