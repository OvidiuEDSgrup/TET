CREATE TABLE [dbo].[menmodule] (
    [Modul]        SMALLINT       NOT NULL,
    [Bara]         CHAR (50)      NOT NULL,
    [Descriere]    CHAR (150)     NOT NULL,
    [Numar]        DECIMAL (9, 4) NOT NULL,
    [Bara_parinte] CHAR (50)      NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[menmodule]([Modul] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_bara]
    ON [dbo].[menmodule]([Modul] ASC, [Bara] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_bara_parinte]
    ON [dbo].[menmodule]([Modul] ASC, [Bara_parinte] ASC);

