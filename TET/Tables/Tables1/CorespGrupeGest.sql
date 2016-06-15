CREATE TABLE [dbo].[CorespGrupeGest] (
    [Grupa]    CHAR (13) NOT NULL,
    [Gestiune] CHAR (9)  NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[CorespGrupeGest]([Grupa] ASC, [Gestiune] ASC);

